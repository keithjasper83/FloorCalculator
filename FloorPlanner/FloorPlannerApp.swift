//
//  FloorPlannerApp.swift
//  FloorPlanner
//
//  Main app entry point
//

import SwiftUI

@main
struct FloorPlannerApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Install crash / error logging before anything else initialises
        DiagnosticsManager.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

