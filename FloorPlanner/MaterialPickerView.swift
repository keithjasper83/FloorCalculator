//
//  MaterialPickerView.swift
//  FloorPlanner
//
//  Dialog for selecting material type
//

import SwiftUI

struct MaterialPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: MaterialType
    @State private var showWarning = false
    
    // Group materials by category for better UI
    private var categories: [String: [MaterialType]] {
        Dictionary(grouping: MaterialType.allCases) { type in
            type.toDomainMaterial.category.rawValue
        }
    }

    // Ordered category keys
    private let categoryOrder: [MaterialCategory] = [.flooring, .wallCovering, .liquid, .structural]

    init() {
        _selectedType = State(initialValue: .laminate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Material Type")
                    .font(.title2)
                    .padding(.top)
                
                Text("Choose the material you'll be working with.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(categoryOrder, id: \.self) { category in
                            if let types = categories[category.rawValue], !types.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)

                                    ForEach(types, id: \.self) { type in
                                        materialTypeButton(type)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                if !appState.isFirstLaunch {
                    Text("⚠️ Changing material type will regenerate the layout with new rules.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Select") {
                        if appState.currentProject.materialType != selectedType {
                            showWarning = true
                        } else {
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .alert("Change Material Type?", isPresented: $showWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Change", role: .destructive) {
                    appState.changeMaterialType(to: selectedType)
                    dismiss()
                }
            } message: {
                Text("This will regenerate the layout with different rules. Your current layout will be replaced.")
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onAppear {
            selectedType = appState.currentProject.materialType
        }
    }
    
    private func materialTypeButton(_ type: MaterialType) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(descriptionFor(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary.opacity(0.3))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedType == type ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedType == type ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func descriptionFor(_ type: MaterialType) -> String {
        switch type {
        case .laminate, .vinylPlank, .engineeredWood:
            return "Row-based layout with stagger rules"
        case .carpetTile, .ceramicTile:
            return "Grid-based layout with pattern options"
        case .concrete:
            return "Volume calculation based on area & depth"
        case .paint:
            return "Coverage calculation based on area"
        case .plasterboard:
            return "Sheet calculation for surface area"
        }
    }
}
