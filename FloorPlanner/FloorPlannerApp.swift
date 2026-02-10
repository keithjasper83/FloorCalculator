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

// MARK: - App State

class AppState: ObservableObject {
    @Published var currentProject: Project
    @Published var layoutResult: LayoutResult?
    @Published var showMaterialPicker = false
    @Published var isFirstLaunch = true
    
    init() {
        // Check if this is first launch
        if UserDefaults.standard.object(forKey: "hasLaunchedBefore") == nil {
            isFirstLaunch = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            isFirstLaunch = false
        }
        
        // Try to load last project or create sample
        if let projects = try? PersistenceManager.shared.listProjects(),
           let lastProject = projects.first {
            currentProject = lastProject
        } else {
            currentProject = Project.sampleLaminateProject()
        }
        
        // Show material picker on first launch
        if isFirstLaunch {
            showMaterialPicker = true
        }
    }
    
    func generateLayout() {
        let engine: LayoutEngine
        
        switch currentProject.materialType {
        case .laminate:
            engine = LaminateEngine()
        case .carpetTile:
            engine = TileEngine()
        }
        
        let useStock = !currentProject.stockItems.isEmpty
        layoutResult = engine.generateLayout(project: currentProject, useStock: useStock)
    }
    
    func changeMaterialType(to newType: MaterialType) {
        currentProject.materialType = newType
        currentProject.modifiedAt = Date()
        
        // Initialize material-specific settings
        if newType == .laminate {
            if currentProject.laminateSettings == nil {
                currentProject.laminateSettings = LaminateSettings(
                    minStaggerMm: 200,
                    minOffcutLengthMm: 150,
                    plankDirection: .alongLength,
                    defaultPlankLengthMm: 1000,
                    defaultPlankWidthMm: 300
                )
            }
        } else {
            if currentProject.tileSettings == nil {
                currentProject.tileSettings = TileSettings(
                    tileSizeMm: 500,
                    pattern: .straight,
                    orientation: .monolithic,
                    reuseEdgeOffcuts: false,
                    tilesPerBox: nil
                )
            }
        }
        
        // Regenerate layout
        generateLayout()
    }
    
    func saveProject() {
        currentProject.modifiedAt = Date()
        try? PersistenceManager.shared.saveProject(currentProject)
    }
}
