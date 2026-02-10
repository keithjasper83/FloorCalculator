//
//  MaterialSettingsView.swift
//  FloorPlanner
//
//  View for material-specific settings (Laminate or Tile)
//

import SwiftUI

struct MaterialSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            switch appState.currentProject.materialType {
            case .laminate:
                laminateSettings
            case .carpetTile:
                tileSettings
            }
        }
    }
    
    // MARK: - Laminate Settings
    
    @ViewBuilder
    private var laminateSettings: some View {
        if let settings = Binding($appState.currentProject.laminateSettings) {
            Section("Default Plank Size") {
                HStack {
                    Text("Length (mm)")
                    Spacer()
                    TextField("Length", value: settings.defaultPlankLengthMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Width (mm)")
                    Spacer()
                    TextField("Width", value: settings.defaultPlankWidthMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Plank Direction") {
                Picker("Direction", selection: settings.plankDirection) {
                    ForEach(LaminateSettings.PlankDirection.allCases, id: \.self) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Installation Rules") {
                HStack {
                    Text("Min Stagger (mm)")
                    Spacer()
                    TextField("Stagger", value: settings.minStaggerMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Min Offcut Length (mm)")
                    Spacer()
                    TextField("Offcut", value: settings.minOffcutLengthMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
        }
    }
    
    // MARK: - Tile Settings
    
    @ViewBuilder
    private var tileSettings: some View {
        if let settings = Binding($appState.currentProject.tileSettings) {
            Section("Tile Size") {
                HStack {
                    Text("Tile Size (mm)")
                    Spacer()
                    TextField("Size", value: settings.tileSizeMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Pattern") {
                Picker("Pattern", selection: settings.pattern) {
                    ForEach(TileSettings.TilePattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue).tag(pattern)
                    }
                }
            }
            
            Section("Orientation") {
                Picker("Orientation", selection: settings.orientation) {
                    ForEach(TileSettings.TileOrientation.allCases, id: \.self) { orientation in
                        Text(orientation.rawValue).tag(orientation)
                    }
                }
            }
            
            Section("Options") {
                Toggle("Reuse Edge Offcuts", isOn: settings.reuseEdgeOffcuts)
                
                HStack {
                    Text("Tiles Per Box")
                    Spacer()
                    TextField("Optional", value: settings.tilesPerBox, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
        }
    }
}
