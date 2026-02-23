//
//  DiagnosticsView.swift
//  FloorPlanner
//
//  In-app viewer for crash reports and error logs written by DiagnosticsManager.
//  Logs can be read, shared (uploaded for diagnosis), or deleted from here.
//

import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logURLs: [URL] = []
    @State private var selectedLog: URL? = nil
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if logURLs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .navigationTitle("Diagnostics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !logURLs.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear All", role: .destructive) {
                            showClearConfirm = true
                        }
                    }
                }
            }
            .confirmationDialog("Delete all diagnostic logs?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    DiagnosticsManager.shared.clearAllLogs()
                    reload()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $selectedLog) { url in
                LogDetailView(url: url)
            }
        }
        .onAppear { reload() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 56))
                .foregroundColor(.green)
            Text("No Diagnostic Logs")
                .font(.title2).fontWeight(.semibold)
            Text("Crash reports and app errors will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    private var logList: some View {
        List {
            ForEach(logURLs, id: \.absoluteString) { url in
                LogRow(url: url)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedLog = url }
            }
            .onDelete { indexSet in
                indexSet.forEach { DiagnosticsManager.shared.deleteLog(at: logURLs[$0]) }
                reload()
            }
        }
    }

    // MARK: - Helpers

    private func reload() {
        logURLs = DiagnosticsManager.shared.listLogs()
    }
}

// MARK: - Log Row

private struct LogRow: View {
    let url: URL

    private var isCrash: Bool { url.lastPathComponent.hasPrefix("crash") }

    private var creationDate: Date? {
        try? url.resourceValues(forKeys: [.creationDateKey]).creationDate
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCrash ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isCrash ? .red : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(isCrash ? "Crash Report" : "Error Report")
                    .font(.headline)
                if let date = creationDate {
                    Text(date, style: .date) + Text(" ") + Text(date, style: .time)
                } else {
                    Text(url.lastPathComponent)
                }
            }
            .foregroundColor(.primary)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log Detail View

private struct LogDetailView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    private var content: String {
        DiagnosticsManager.shared.readLog(at: url)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(url.lastPathComponent)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: url, subject: Text("Diagnostic Log"), message: Text("FloorPlanner diagnostic log")) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - URL + Identifiable

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
