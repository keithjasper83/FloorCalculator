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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

