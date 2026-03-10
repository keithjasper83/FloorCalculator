//
//  DiagnosticsManager.swift
//  FloorPlanner
//
//  Records crash reports and app-level errors to disk so they can be
//  viewed in-app and shared for diagnosis.
//

import Foundation
import OSLog

// MARK: - Module-level globals for async-signal-safe signal handler access
//
// These are written once at install() time and then read-only from the
// @convention(c) signal handler, which cannot safely use the Swift runtime.
private var gSignalCrashLogPath = [CChar](repeating: 0, count: 4096)

// @convention(c) signal handler: only calls open/write/close (async-signal-safe).
private let crashSignalHandler: @convention(c) (Int32) -> Void = { sig in
    // Build content using only C-level primitives
    var content = [CChar](repeating: 0, count: 128)
    _ = snprintf(&content, 128, "Signal crash: %d\nSee iOS system crash report for full symbolication.\n", sig)

    let fd = open(gSignalCrashLogPath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
    if fd >= 0 {
        _ = write(fd, &content, strlen(content))
        _ = Darwin.close(fd)
    }

    // Restore default handler and re-raise so the OS gets its crash report too
    signal(sig, SIG_DFL)
    raise(sig)
}

// MARK: - DiagnosticsManager

final class DiagnosticsManager {

    static let shared = DiagnosticsManager()

    private let logger: Logger
    let logsDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logsDirectory = docs.appendingPathComponent("DiagnosticLogs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        if #available(iOS 14.0, macOS 11.0, *) {
            self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FloorPlanner", category: "Diagnostics")
        } else {
            // Dummy logger for older platforms
            self.logger = Logger(OSLog.disabled)
        }
    }

    // MARK: - Install (call once at app startup, before any other code runs)

    func install() {
        // Archive any crash marker left by the PREVIOUS session before we set up the
        // new session's path. This ensures a crash that fires immediately after install()
        // writes to the pending file rather than racing with archiving.
        archivePendingSignalCrash()

        // Pre-store the crash log path in a C-safe global for the signal handler.
        // Use count-1 as the copy limit to guarantee space for the null terminator.
        let signalCrashPath = logsDirectory.appendingPathComponent("crash_signal_pending.txt").path
        signalCrashPath.withCString { ptr in
            let len = strlen(ptr)
            let copyLen = min(len, gSignalCrashLogPath.count - 1)
            _ = memcpy(&gSignalCrashLogPath, ptr, copyLen)
            gSignalCrashLogPath[Int(copyLen)] = 0
        }

        // Uncaught Objective-C / Swift exception handler (Foundation-safe context)
        NSSetUncaughtExceptionHandler { exception in
            DiagnosticsManager.shared.writeExceptionReport(exception)
        }

        // POSIX signal handlers (async-signal-safe C handler above)
        for sig in [SIGABRT, SIGSEGV, SIGILL, SIGBUS, SIGTRAP] {
            signal(sig, crashSignalHandler)
        }
    }

    // MARK: - App-level error logging

    @discardableResult
    func log(error: Error, context: String? = nil) -> String {
        let message = "Error\(context.map { " [\($0)]" } ?? ""): \(error.localizedDescription)"
        if #available(iOS 14.0, macOS 11.0, *) {
            logger.error("\(message, privacy: .public)")
        } else {
            print("[Diagnostics] \(message)")
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let content = """
        --- Error Report ---
        Date:    \(timestamp)
        Context: \(context ?? "None")
        Error:   \(error.localizedDescription)
        Detail:  \(String(describing: error))
        """
        write(content: content, prefix: "error")

        return message
    }

    /// Logs an arbitrary message with a level and optional context.
    enum Level: String { case debug, info, warn, error }

    func log(_ message: String, level: Level = .info, context: String? = nil) {
        let composed = "\(level.rawValue.uppercased())\(context.map { " [\($0)]" } ?? ""): \(message)"
        if #available(iOS 14.0, macOS 11.0, *) {
            switch level {
            case .debug: logger.debug("\(composed, privacy: .public)")
            case .info:  logger.info("\(composed, privacy: .public)")
            case .warn:  logger.warning("\(composed, privacy: .public)")
            case .error: logger.error("\(composed, privacy: .public)")
            }
        } else {
            print("[Diagnostics] \(composed)")
        }
    }

    /// Records a named event with optional metadata for analytics/debugging.
    func event(_ name: String, metadata: [String: String] = [:], context: String? = nil) {
        let metaString = metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
        let composed = metaString.isEmpty ? name : "\(name) {\(metaString)}"
        if #available(iOS 14.0, macOS 11.0, *) {
            logger.log("EVENT\(context.map { " [\($0)]" } ?? ""): \(composed, privacy: .public)")
        } else {
            print("[Diagnostics] EVENT\(context.map { " [\($0)]" } ?? ""): \(composed)")
        }
    }

    // MARK: - Log management

    func listLogs() -> [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
        return urls
            .filter { $0.pathExtension == "txt" }
            .sorted { a, b in
                let dA = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let dB = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return dA > dB
            }
    }

    func readLog(at url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? "Could not read log file."
    }

    func deleteLog(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func clearAllLogs() {
        listLogs().forEach { deleteLog(at: $0) }
    }

    // MARK: - Private helpers

    private func writeExceptionReport(_ exception: NSException) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let stack = exception.callStackSymbols.joined(separator: "\n")
        let content = """
        --- Crash Report (Uncaught Exception) ---
        Date:      \(timestamp)
        Exception: \(exception.name.rawValue)
        Reason:    \(exception.reason ?? "Unknown")

        Call Stack:
        \(stack)
        """
        write(content: content, prefix: "crash")
    }

    private func write(content: String, prefix: String) {
        let ts = Int(Date().timeIntervalSince1970)
        let filename = "\(prefix)_\(ts).txt"
        let url = logsDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Renames a pending signal crash marker (left by a previous session) to a dated file.
    private func archivePendingSignalCrash() {
        let markerURL = logsDirectory.appendingPathComponent("crash_signal_pending.txt")
        guard FileManager.default.fileExists(atPath: markerURL.path) else { return }
        let ts = Int(Date().timeIntervalSince1970)
        let archiveURL = logsDirectory.appendingPathComponent("crash_signal_\(ts).txt")
        try? FileManager.default.moveItem(at: markerURL, to: archiveURL)
    }
}
