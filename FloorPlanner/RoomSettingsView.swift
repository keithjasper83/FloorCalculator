//
//  RoomSettingsView.swift
//  FloorPlanner
//
//  View for configuring room dimensions and settings
//

import SwiftUI

struct RoomSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDesigner = false
    @State private var showARScanner = false
    
    var body: some View {
        Form {
            Section("Room Type") {
                Picker("Shape", selection: $appState.currentProject.roomSettings.shape) {
                    ForEach(RoomShape.allCases, id: \.self) { shape in
                        Text(shape.rawValue).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
                
                if appState.currentProject.roomSettings.shape == .polygon {
                    Button(action: { showDesigner = true }) {
                        HStack {
                            Image(systemName: "pencil.and.ruler")
                            Text("Design Custom Room")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !appState.currentProject.roomSettings.polygonPoints.isEmpty {
                        HStack {
                            Text("Points Defined")
                            Spacer()
                            Text("\(appState.currentProject.roomSettings.polygonPoints.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if appState.currentProject.roomSettings.shape == .rectangular {
                Section("Room Dimensions") {
                    #if os(iOS)
                    Button(action: { showARScanner = true }) {
                        Label("Scan Room with AR", systemImage: "camera.viewfinder")
                    }
                    #endif

                    HStack {
                        Text("Length (mm)")
                        Spacer()
                        TextField("Length", value: $appState.currentProject.roomSettings.lengthMm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Width (mm)")
                        Spacer()
                        TextField("Width", value: $appState.currentProject.roomSettings.widthMm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            
            Section("Expansion Gap") {
                HStack {
                    Text("Expansion Gap (mm)")
                    Spacer()
                    TextField("Gap", value: $appState.currentProject.roomSettings.expansionGapMm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            
            Section("Installation Pattern") {
                Picker("Pattern", selection: $appState.currentProject.roomSettings.patternType) {
                    ForEach(InstallationPattern.allCases, id: \.self) { pattern in
                        Text(pattern.rawValue).tag(pattern)
                    }
                }
                .pickerStyle(.segmented)

                if appState.currentProject.roomSettings.patternType == .diagonal {
                    VStack {
                        HStack {
                            Text("Angle")
                            Spacer()
                            Text("\(Int(appState.currentProject.roomSettings.angleDegrees))°")
                        }
                        Slider(value: $appState.currentProject.roomSettings.angleDegrees, in: 0...60, step: 1)

                        // Presets
                        HStack {
                            Button("0°") { appState.currentProject.roomSettings.angleDegrees = 0 }
                            Spacer()
                            Button("22.5°") { appState.currentProject.roomSettings.angleDegrees = 22.5 }
                            Spacer()
                            Button("45°") { appState.currentProject.roomSettings.angleDegrees = 45 }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }

            Section("Calculated Areas") {
                HStack {
                    Text("Gross Area")
                    Spacer()
                    Text("\(appState.currentProject.roomSettings.grossAreaM2, specifier: "%.2f") m²")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Usable Area")
                    Spacer()
                    Text("\(appState.currentProject.roomSettings.usableAreaM2, specifier: "%.2f") m²")
                        .foregroundColor(.secondary)
                }
                
                if appState.currentProject.roomSettings.shape == .polygon {
                    HStack {
                        Text("Bounding Box")
                        Spacer()
                        Text("\(Int(appState.currentProject.roomSettings.boundingLengthMm))×\(Int(appState.currentProject.roomSettings.boundingWidthMm))mm")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Waste Factor") {
                HStack {
                    Text("Waste Factor (%)")
                    Spacer()
                    TextField("Waste", value: $appState.currentProject.wasteFactor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
        }
        .sheet(isPresented: $showDesigner) {
            RoomDesignerView()
        }
        .sheet(isPresented: $showARScanner) {
            ARCaptureView(roomSettings: $appState.currentProject.roomSettings)
        }
    }
}
