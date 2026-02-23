import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("App Info") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Device") {
                    #if os(iOS)
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(UIDevice.current.model)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("System")
                        Spacer()
                        Text("iOS \(UIDevice.current.systemVersion)")
                            .foregroundStyle(.secondary)
                    }
                    #else
                    HStack {
                        Text("System")
                        Spacer()
                        Text(ProcessInfo.processInfo.operatingSystemVersionString)
                            .foregroundStyle(.secondary)
                    }
                    #endif
                }
            }
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DiagnosticsView()
}
