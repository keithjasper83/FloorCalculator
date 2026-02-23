import Foundation
import OSLog

final class DiagnosticsManager {
    static let shared = DiagnosticsManager()

    private let logger: Logger

    private init() {
        if #available(iOS 14.0, macOS 11.0, *) {
            self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FloorPlanner", category: "Diagnostics")
        } else {
            // Dummy logger for older platforms
            self.logger = Logger(OSLog.disabled)
        }
    }

    /// Install crash / error logging before anything else initializes.
    /// Replace the body of this method with integration to your diagnostics provider
    /// (e.g., Crashlytics, Sentry, OSLog setup, etc.).
    func install() {
        // TODO: Set up diagnostics/crash reporting here
        // For now, this is a no-op to allow the app to compile and run.
    }

    // MARK: - Public API used across the app

    /// Records an error with optional context string.
    @discardableResult
    func log(error: Error, context: String? = nil) -> String {
        let message = "Error\(context.map { " [\($0)]" } ?? ""): \(error.localizedDescription)"
        if #available(iOS 14.0, macOS 11.0, *) {
            logger.error("\(message, privacy: .public)")
        } else {
            print("[Diagnostics] \(message)")
        }
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
}
