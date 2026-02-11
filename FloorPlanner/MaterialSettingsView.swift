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
            case .laminate, .vinylPlank, .engineeredWood:
                laminateSettings
            case .carpetTile, .ceramicTile:
                tileSettings
            case .concrete, .paint, .plasterboard:
                continuousSettings
            }
        }
    }
    
    // MARK: - Laminate Settings
    
    @ViewBuilder
    private var laminateSettings: some View {
        if appState.currentProject.laminateSettings != nil {
            Section("Default Plank Size") {
                HStack {
                    Text("Length (mm)")
                    Spacer()
                    TextField("Length", value: laminateDefaultPlankLengthBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Width (mm)")
                    Spacer()
                    TextField("Width", value: laminateDefaultPlankWidthBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Plank Direction") {
                Picker("Direction", selection: laminatePlankDirectionBinding) {
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
                    TextField("Stagger", value: laminateMinStaggerBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Min Offcut Length (mm)")
                    Spacer()
                    TextField("Offcut", value: laminateMinOffcutBinding, format: .number)
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
        if appState.currentProject.tileSettings != nil {
            Section("Tile Size") {
                HStack {
                    Text("Tile Size (mm)")
                    Spacer()
                    TextField("Size", value: tileSizeBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Pattern") {
                Picker("Pattern", selection: tilePatternBinding) {
                    ForEach(TileSettings.TilePattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue).tag(pattern)
                    }
                }
            }
            
            Section("Orientation") {
                Picker("Orientation", selection: tileOrientationBinding) {
                    ForEach(TileSettings.TileOrientation.allCases, id: \.self) { orientation in
                        Text(orientation.rawValue).tag(orientation)
                    }
                }
            }
            
            Section("Options") {
                Toggle("Reuse Edge Offcuts", isOn: tileReuseOffcutsBinding)
                
                HStack {
                    Text("Tiles Per Box")
                    Spacer()
                    TextField("Optional", value: tilesPerBoxBinding, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
        }
    }
    
    // MARK: - Continuous Settings

    @ViewBuilder
    private var continuousSettings: some View {
        Section("Layer Properties") {
            HStack {
                Text("Thickness (mm)")
                Spacer()
                TextField("Thickness", value: layerThicknessBinding, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
        }

        Section("Information") {
            Text("Calculated based on area and coverage.")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Bindings

    private var layerThicknessBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.layers.first?.thicknessMm ?? 0.0 },
            set: { newValue in
                if !appState.currentProject.layers.isEmpty {
                    appState.currentProject.layers[0].thicknessMm = newValue
                }
            }
        )
    }

    // MARK: - Laminate Bindings

    private var laminateDefaultPlankLengthBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.laminateSettings?.defaultPlankLengthMm ?? 1000 },
            set: { appState.currentProject.laminateSettings?.defaultPlankLengthMm = $0 }
        )
    }

    private var laminateDefaultPlankWidthBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.laminateSettings?.defaultPlankWidthMm ?? 300 },
            set: { appState.currentProject.laminateSettings?.defaultPlankWidthMm = $0 }
        )
    }

    private var laminatePlankDirectionBinding: Binding<LaminateSettings.PlankDirection> {
        Binding(
            get: { appState.currentProject.laminateSettings?.plankDirection ?? .alongLength },
            set: { appState.currentProject.laminateSettings?.plankDirection = $0 }
        )
    }

    private var laminateMinStaggerBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.laminateSettings?.minStaggerMm ?? 200 },
            set: { appState.currentProject.laminateSettings?.minStaggerMm = $0 }
        )
    }

    private var laminateMinOffcutBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.laminateSettings?.minOffcutLengthMm ?? 150 },
            set: { appState.currentProject.laminateSettings?.minOffcutLengthMm = $0 }
        )
    }

    // MARK: - Tile Bindings
    
    private var tileSizeBinding: Binding<Double> {
        Binding(
            get: { appState.currentProject.tileSettings?.tileSizeMm ?? 500 },
            set: { appState.currentProject.tileSettings?.tileSizeMm = $0 }
        )
    }
    
    private var tilePatternBinding: Binding<TileSettings.TilePattern> {
        Binding(
            get: { appState.currentProject.tileSettings?.pattern ?? .straight },
            set: { appState.currentProject.tileSettings?.pattern = $0 }
        )
    }
    
    private var tileOrientationBinding: Binding<TileSettings.TileOrientation> {
        Binding(
            get: { appState.currentProject.tileSettings?.orientation ?? .monolithic },
            set: { appState.currentProject.tileSettings?.orientation = $0 }
        )
    }
    
    private var tileReuseOffcutsBinding: Binding<Bool> {
        Binding(
            get: { appState.currentProject.tileSettings?.reuseEdgeOffcuts ?? false },
            set: { appState.currentProject.tileSettings?.reuseEdgeOffcuts = $0 }
        )
    }
    
    private var tilesPerBoxBinding: Binding<Int?> {
        Binding(
            get: { appState.currentProject.tileSettings?.tilesPerBox },
            set: { appState.currentProject.tileSettings?.tilesPerBox = $0 }
        )
    }
}
