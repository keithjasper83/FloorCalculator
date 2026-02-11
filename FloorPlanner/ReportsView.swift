//
//  ReportsView.swift
//  FloorPlanner
//
//  View for displaying layout reports and statistics
//

import Foundation
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            if let result = appState.layoutResult {
                VStack(spacing: 20) {
                    // Area Summary
                    GroupBox("Area Summary") {
                        VStack(alignment: .leading, spacing: 8) {
                            reportRow("Room Area", value: "\(appState.currentProject.roomSettings.grossAreaM2.formatted(.number.precision(.fractionLength(2)))) m²")
                            reportRow("Usable Area", value: "\(appState.currentProject.roomSettings.usableAreaM2.formatted(.number.precision(.fractionLength(2)))) m²")
                            reportRow("Installed Coverage", value: "\(result.installedAreaM2.formatted(.number.precision(.fractionLength(2)))) m²")
                            
                            if result.neededAreaM2 > Constants.areaToleranceM2 {
                                reportRow("Needed Coverage", value: "\(result.neededAreaM2.formatted(.number.precision(.fractionLength(2)))) m²", color: .red)
                            }
                            
                            reportRow("Waste Area", value: "\(result.wasteAreaM2.formatted(.number.precision(.fractionLength(2)))) m²")
                            
                            if result.surplusAreaM2 > Constants.areaToleranceM2 {
                                reportRow("Surplus", value: "\(result.surplusAreaM2.formatted(.number.precision(.fractionLength(2)))) m²", color: .green)
                            }
                            
                            Divider()
                            
                            let usableArea = appState.currentProject.roomSettings.usableAreaM2
                            let completionPercent: Double
                            if usableArea > 0 {
                                completionPercent = (result.installedAreaM2 / usableArea) * 100
                            } else {
                                completionPercent = 0
                            }
                            reportRow("Completion", value: "\(completionPercent.formatted(.number.precision(.fractionLength(1))))%",
                                     color: completionPercent >= 99.9 ? .green : .orange)
                        }
                    }
                    
                    // Purchase Suggestions
                    if !result.purchaseSuggestions.isEmpty {
                        GroupBox("Purchase Suggestions") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.purchaseSuggestions) { suggestion in
                                    VStack(alignment: .leading, spacing: 4) {
                                        if suggestion.unitLengthMm > 0 && suggestion.unitWidthMm > 0 {
                                            Text("\(Int(suggestion.unitLengthMm)) × \(Int(suggestion.unitWidthMm)) mm")
                                                .font(.headline)
                                        } else {
                                            Text("Calculated Material")
                                                .font(.headline)
                                        }

                                        // Show Quantity (Integer or Double based on type)
                                        if appState.currentProject.materialType.toDomainMaterial.calculationType == .continuous {
                                             Text("Quantity: \(suggestion.quantityValue.formatted(.number.precision(.fractionLength(2)))) units")
                                        } else {
                                             Text("Quantity: \(suggestion.quantityNeeded)")
                                        }

                                        if let packs = suggestion.packsNeeded {
                                            Text("Packs/Boxes: \(packs)")
                                                .foregroundColor(.secondary)
                                        }

                                        if let cost = suggestion.estimatedCost {
                                            Text("Est. Cost: \(cost.formatted(.currency(code: appState.currentProject.currency)))")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                        }
                    }
                    
                    // Sections for Discrete Materials Only
                    if appState.currentProject.materialType.toDomainMaterial.calculationType == .discrete {
                        // Cut List
                        if !result.cutRecords.isEmpty {
                            GroupBox("Cut List") {
                                VStack(alignment: .leading, spacing: 8) {
                                    if appState.currentProject.materialType == .laminate {
                                        ForEach(result.cutRecords) { cut in
                                            if let row = cut.row, let cutType = cut.cutType {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("Row \(row + 1): \(cutType.rawValue)")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                    if let from = cut.fromLengthMm, let to = cut.cutToMm {
                                                        Text("\(Int(from))mm → \(Int(to))mm")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                .padding(.vertical, 2)
                                            }
                                        }
                                    } else {
                                        ForEach(result.cutRecords) { cut in
                                            if let edgeCount = cut.edgeCutCount {
                                                Text("Edge Cuts: \(edgeCount)")
                                                if let dims = cut.cutDimensionsMm {
                                                    Text(dims)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Remaining Inventory
                        if !result.remainingPieces.isEmpty {
                            GroupBox("Remaining Inventory") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(result.remainingPieces) { piece in
                                        HStack {
                                            Text("\(Int(piece.lengthMm)) × \(Int(piece.widthMm)) mm")
                                            Spacer()
                                            Text(piece.source.rawValue)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Placement Statistics
                        GroupBox("Placement Statistics") {
                            VStack(alignment: .leading, spacing: 8) {
                                let installedCount = result.placedPieces.filter { $0.status == .installed }.count
                                let neededCount = result.placedPieces.filter { $0.status == .needed }.count

                                reportRow("Pieces Installed", value: "\(installedCount)")
                                if neededCount > 0 {
                                    reportRow("Pieces Needed", value: "\(neededCount)", color: .red)
                                }
                                reportRow("Total Pieces", value: "\(result.placedPieces.count)")
                            }
                        }
                    } // End Discrete Only
                    
                    // Export buttons
                    VStack(spacing: 12) {
                        Button {
                            exportAllCSVs()
                        } label: {
                            Label("Export All Reports (CSV)", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                .padding()
            } else {
                Text("No reports available")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Reports")
    }
    
    private func reportRow(_ label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    private func exportAllCSVs() {
        guard let result = appState.layoutResult else { return }
        
        let persistence = PersistenceManager.shared
        let placementCSV = persistence.exportPlacementCSV(result: result)
        let cutListCSV = persistence.exportCutListCSV(result: result, materialType: appState.currentProject.materialType)
        let inventoryCSV = persistence.exportRemainingInventoryCSV(result: result)
        let purchaseCSV = persistence.exportPurchaseListCSV(result: result)
        
        // TODO: Implement actual file export with ShareSheet/NSSavePanel
        print("Placement CSV:\n\(placementCSV)")
        print("\nCut List CSV:\n\(cutListCSV)")
        print("\nInventory CSV:\n\(inventoryCSV)")
        print("\nPurchase CSV:\n\(purchaseCSV)")
    }
}
