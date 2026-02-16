//
//  AppState.swift
//  FloorPlanner
//
//  Global application state
//

import SwiftUI

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
        case .laminate, .vinylPlank, .engineeredWood:
            engine = LaminateEngine()
        case .carpetTile, .ceramicTile:
            engine = TileEngine()
        case .plasterboard:
            // Plasterboard is discrete (sheets), use TileEngine for sheet-based layout
            engine = TileEngine()
        case .concrete, .paint:
            // For continuous materials, we use CalculatedEngine
            // We need to pass the material definition.
            // Since we are using legacy materialType switch, we can map it back.
            let material = currentProject.materialType.toDomainMaterial

            // Get thickness from the layer if available, or default
            let thickness = currentProject.layers.first?.thicknessMm ?? material.defaultThicknessMm ?? 0.0

            engine = CalculatedEngine(material: material, thicknessMm: thickness)
        }

        let useStock = !currentProject.stockItems.isEmpty
        layoutResult = engine.generateLayout(project: currentProject, useStock: useStock)
    }

    func changeMaterialType(to newType: MaterialType) {
        currentProject.materialType = newType
        currentProject.modifiedAt = Date()

        // Initialize material-specific settings if needed
        // (Project.materialType setter handles layer creation)

        // Regenerate layout
        generateLayout()
    }

    func saveProject() {
        currentProject.modifiedAt = Date()
        try? PersistenceManager.shared.saveProject(currentProject)
    }
}
