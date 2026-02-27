//
//  ContentView.swift
//  FloorPlanner
//
//  Main view with adaptive layout for iPhone, iPad, and Mac
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDiagnostics = false
    @State private var macSelection: MacSidebarItem? = .roomSettings
    
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

                        Button("Diagnostics") {
                            showDiagnostics = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $appState.showMaterialPicker) {
                MaterialPickerView()
            }
            .sheet(isPresented: $showDiagnostics) {
                DiagnosticsView()
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
            macSidebar
        } detail: {
            macDetailView
        }
        .sheet(isPresented: $appState.showMaterialPicker) {
            MaterialPickerView()
        }
    }

    private var macSidebar: some View {
        List(selection: $macSelection) {
            Section("Inputs") {
                NavigationLink(value: MacSidebarItem.roomSettings) {
                    Label("Room Settings", systemImage: "ruler")
                }
                NavigationLink(value: MacSidebarItem.stockItems) {
                    Label("Stock Items", systemImage: "shippingbox")
                }
                NavigationLink(value: MacSidebarItem.materialSettings) {
                    Label("Material Settings", systemImage: "slider.horizontal.3")
                }
            }

            Section("Outputs") {
                NavigationLink(value: MacSidebarItem.preview) {
                    Label("Preview", systemImage: "square.grid.2x2")
                }
                .disabled(appState.layoutResult == nil)

                NavigationLink(value: MacSidebarItem.reports) {
                    Label("Reports", systemImage: "chart.bar")
                }
                .disabled(appState.layoutResult == nil)
            }

            Section("Project") {
                HStack {
                    Text("Material")
                    Spacer()
                    Text(appState.currentProject.materialType.rawValue)
                        .foregroundColor(.secondary)
                }

                Button("Generate Layout") {
                    appState.generateLayout()
                }
                .buttonStyle(.borderedProminent)

                Button("Save Project") {
                    appState.saveProject()
                }
            }
        }
        .navigationTitle("Floor Planner")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("Change Material Type") {
                        appState.showMaterialPicker = true
                    }
                    Button("Diagnostics") {
                        showDiagnostics = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView()
        }
    }

    @ViewBuilder
    private var macDetailView: some View {
        switch macSelection ?? .roomSettings {
        case .roomSettings:
            RoomSettingsView()
                .navigationTitle("Room Settings")
        case .stockItems:
            StockTableView()
                .navigationTitle("Stock Items")
        case .materialSettings:
            MaterialSettingsView()
                .navigationTitle("Material Settings")
        case .preview:
            if appState.layoutResult != nil {
                PreviewView()
                    .navigationTitle("Preview")
            } else {
                macPlaceholder
            }
        case .reports:
            if appState.layoutResult != nil {
                ReportsView()
                    .navigationTitle("Reports")
            } else {
                macPlaceholder
            }
        }
    }

    private var macPlaceholder: some View {
        VStack {
            Image(systemName: "square.dashed")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Generate a layout to see preview")
                .font(.title2)
                .foregroundColor(.secondary)
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

                    Button("Diagnostics") {
                        showDiagnostics = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView()
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

private enum MacSidebarItem: Hashable {
    case roomSettings
    case stockItems
    case materialSettings
    case preview
    case reports
}

#if os(iOS)
#Preview("Content · iPhone") {
    ContentView()
        .environmentObject(PreviewFactory.appState(materialType: .laminate, includeLayout: true))
}

#Preview("Content · iPad") {
    ContentView()
        .environmentObject(PreviewFactory.appState(materialType: .ceramicTile, includeLayout: true))
}
#else
#Preview("Content · macOS") {
    ContentView()
        .environmentObject(PreviewFactory.appState(materialType: .laminate, includeLayout: true))
}
#endif
