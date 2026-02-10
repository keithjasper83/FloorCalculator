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
    
    init() {
        _selectedType = State(initialValue: .laminate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Material Type")
                    .font(.title2)
                    .padding(.top)
                
                Text("Choose the type of flooring material you'll be working with.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    materialTypeButton(.laminate)
                    materialTypeButton(.carpetTile)
                }
                .padding()
                
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
                        .font(.headline)
                    
                    Text(type == .laminate
                         ? "Row-based layout with stagger rules"
                         : "Grid-based layout with pattern options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
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
}
