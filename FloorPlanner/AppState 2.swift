import Foundation
import SwiftUI

final class AppState: ObservableObject {
    // MARK: - Published State
    @Published var currentProject: Project
    @Published var layoutResult: LayoutResult?
    @Published var showMaterialPicker: Bool = false
    @Published var isFirstLaunch: Bool

    // MARK: - Init
    init() {
        let defaults = UserDefaults.standard
        let hasLaunchedKey = "hasLaunchedBefore"
        if !defaults.bool(forKey: hasLaunchedKey) {
            // First launch
            defaults.set(true, forKey: hasLaunchedKey)
            self.isFirstLaunch = true
        } else {
            self.isFirstLaunch = false
        }

        // Start with a sample project to ensure UI has data
        self.currentProject = Project.sampleLaminateProject()
        self.layoutResult = nil
    }

    // MARK: - Actions

    @MainActor
    func generateLayout() {
        let type = currentProject.materialType
        let useStock = !currentProject.stockItems.isEmpty

        switch type {
        case .laminate, .vinylPlank, .engineeredWood:
            let engine = LaminateEngine()
            let result = engine.generateLayout(project: currentProject, useStock: useStock)
            self.layoutResult = result

        case .carpetTile, .ceramicTile:
            let engine = TileEngine()
            let result = engine.generateLayout(project: currentProject, useStock: useStock)
            self.layoutResult = result

        case .concrete, .paint, .plasterboard:
            let material = currentProject.layers.first?.material ?? type.toDomainMaterial
            let thickness = currentProject.layers.first?.thicknessMm ?? (material.defaultThicknessMm ?? 0)
            let engine = CalculatedEngine(material: material, thicknessMm: thickness)
            let result = engine.generateLayout(project: currentProject, useStock: false)
            self.layoutResult = result
        }
    }

    func changeMaterialType(to newType: MaterialType) {
        // Update material type (Project setter ensures associated settings exist)
        currentProject.materialType = newType
        // Clear existing result; caller can regenerate
        layoutResult = nil
    }

    func saveProject() {
        currentProject.modifiedAt = Date()
        do {
            try PersistenceManager.shared.saveProject(currentProject)
        } catch {
            DiagnosticsManager.shared.log(error: error, context: "AppState.saveProject")
        }
    }

    func saveProjectSilently() {
        saveProject()
    }
}
