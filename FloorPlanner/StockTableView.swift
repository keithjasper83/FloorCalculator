//
//  StockTableView.swift
//  FloorPlanner
//
//  View for managing stock items
//

import SwiftUI

struct StockTableView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddStock = false
    
    var body: some View {
        Form {
            Section {
                if appState.currentProject.stockItems.isEmpty {
                    Text("No stock items. Using default unit size.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach($appState.currentProject.stockItems) { $item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(item.lengthMm)) × \(Int(item.widthMm)) mm")
                                    .font(.headline)
                                Text("Qty: \(item.quantity)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(item.areaM2, specifier: "%.2f") m²")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteStock)
                }
            }
            
            Section {
                Button {
                    showingAddStock = true
                } label: {
                    Label("Add Stock Item", systemImage: "plus.circle.fill")
                }
            }
            
            if !appState.currentProject.stockItems.isEmpty {
                Section("Total Stock Area") {
                    let totalArea = appState.currentProject.stockItems.reduce(0.0) { $0 + $1.areaM2 }
                    Text("\(totalArea, specifier: "%.2f") m²")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingAddStock) {
            AddStockItemView()
        }
    }
    
    private func deleteStock(at offsets: IndexSet) {
        appState.currentProject.stockItems.remove(atOffsets: offsets)
    }
}

struct AddStockItemView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var lengthMm: String = "1000"
    @State private var widthMm: String = "300"
    @State private var quantity: String = "1"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dimensions") {
                    TextField("Length (mm)", text: $lengthMm)
                        .keyboardType(.decimalPad)
                    
                    TextField("Width (mm)", text: $widthMm)
                        .keyboardType(.decimalPad)
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Stock Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStockItem()
                    }
                }
            }
        }
    }
    
    private func addStockItem() {
        guard let length = Double(lengthMm),
              let width = Double(widthMm),
              let qty = Int(quantity),
              length > 0, width > 0, qty > 0 else {
            return
        }
        
        let item = StockItem(lengthMm: length, widthMm: width, quantity: qty)
        appState.currentProject.stockItems.append(item)
        dismiss()
    }
}
