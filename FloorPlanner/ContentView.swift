//
//  ContentView.swift
//  FloorPlanner
//
//  Main view with adaptive layout for iPhone, iPad, and Mac
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        // Mac Catalyst: Split view
        macView
        #elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: Split view
            iPadView
        } else {
            // iPhone: Navigation stack
            iPhoneView
        }
        #else
        // macOS: Split view
        macView
        #endif
    }
    
    // MARK: - iPhone View
    
    #if os(iOS)
    private var iPhoneView: some View {
        NavigationStack {
            List {
                Section {
                    materialTypeRow
                }
                
                Section("Room Settings") {
                    NavigationLink("Configure Room") {
                        RoomSettingsView()
                    }
                }
                
                Section("Stock Items") {
                    NavigationLink("Manage Stock") {
                        StockTableView()
                    }
                }
                
                Section("Material Settings") {
                    NavigationLink("Material Options") {
                        MaterialSettingsView()
                    }
                }
                
                Section {
                    Button("Generate Layout") {
                        appState.generateLayout()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if appState.layoutResult != nil {
                    Section("Results") {
                        NavigationLink("View Preview") {
                            PreviewView()
                        }
                        
                        NavigationLink("View Reports") {
                            ReportsView()
                        }
                    }
                }
            }
            .navigationTitle("Floor Planner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Change Material Type") {
                            appState.showMaterialPicker = true
                        }
                        
                        Button("Save Project") {
                            appState.saveProject()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $appState.showMaterialPicker) {
                MaterialPickerView()
            }
        }
    }
    
    // MARK: - iPad View
    
    private var iPadView: some View {
        NavigationSplitView {
            // Sidebar
            inputsSidebar
        } detail: {
            // Detail view
            if appState.layoutResult != nil {
                TabView {
                    PreviewView()
                        .tabItem {
                            Label("Preview", systemImage: "square.grid.2x2")
                        }
                    
                    ReportsView()
                        .tabItem {
                            Label("Reports", systemImage: "chart.bar")
                        }
                }
            } else {
                VStack {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Generate a layout to see preview")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $appState.showMaterialPicker) {
            MaterialPickerView()
        }
    }
    #endif
    
    // MARK: - Mac View
    
    private var macView: some View {
        NavigationSplitView {
            inputsSidebar
        } detail: {
            if appState.layoutResult != nil {
                TabView {
                    PreviewView()
                        .tabItem {
                            Label("Preview", systemImage: "square.grid.2x2")
                        }
                    
                    ReportsView()
                        .tabItem {
                            Label("Reports", systemImage: "chart.bar")
                        }
                }
            } else {
                VStack {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Generate a layout to see preview")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $appState.showMaterialPicker) {
            MaterialPickerView()
        }
    }
    
    // MARK: - Shared Components
    
    private var inputsSidebar: some View {
        List {
            Section {
                materialTypeRow
            }
            
            Section("Room Settings") {
                RoomSettingsView()
            }
            
            Section("Stock Items") {
                StockTableView()
            }
            
            Section("Material Settings") {
                MaterialSettingsView()
            }
            
            Section {
                Button("Generate Layout") {
                    appState.generateLayout()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Floor Planner")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Change Material Type") {
                        appState.showMaterialPicker = true
                    }
                    
                    Button("Save Project") {
                        appState.saveProject()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var materialTypeRow: some View {
        HStack {
            Label("Material Type", systemImage: "square.stack.3d.up")
            Spacer()
            Text(appState.currentProject.materialType.rawValue)
                .foregroundColor(.secondary)
        }
    }
}
