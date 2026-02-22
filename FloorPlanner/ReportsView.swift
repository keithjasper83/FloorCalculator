//
//  ReportsView.swift
//  FloorPlanner
//
//  View for displaying layout reports and statistics
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
                            
                            reportRow(
                                "Completion",
                                value: "\(((appState.currentProject.roomSettings.usableAreaM2 > 0) ? ((result.installedAreaM2 / appState.currentProject.roomSettings.usableAreaM2) * 100) : 0).formatted(.number.precision(.fractionLength(1))))%",
                                color: ((appState.currentProject.roomSettings.usableAreaM2 > 0) ? ((result.installedAreaM2 / appState.currentProject.roomSettings.usableAreaM2) * 100) : 0) >= 99.9 ? .green : .orange
                            )
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
                                             let unitName = suggestion.unitName ?? "units"
                                             Text("Quantity: \(suggestion.quantityValue.formatted(.number.precision(.fractionLength(2)))) \(unitName)")
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

        let placementCSV = PersistenceManager.shared.exportPlacementCSV(result: result)
        let cutListCSV = PersistenceManager.shared.exportCutListCSV(result: result, materialType: appState.currentProject.materialType)
        let remainingCSV = PersistenceManager.shared.exportRemainingInventoryCSV(result: result)
        let purchaseCSV = PersistenceManager.shared.exportPurchaseListCSV(result: result)

        let baseName = appState.currentProject.name.replacingOccurrences(of: "/", with: "-")
        let files: [(name: String, data: Data)] = [
            ("\(baseName) - Placements.csv", Data(placementCSV.utf8)),
            ("\(baseName) - CutList.csv", Data(cutListCSV.utf8)),
            ("\(baseName) - Remaining.csv", Data(remainingCSV.utf8)),
            ("\(baseName) - Purchases.csv", Data(purchaseCSV.utf8))
        ]

        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.title = "Select Export Folder"
        if panel.runModal() == .OK, let folderURL = panel.url {
            for file in files {
                let url = folderURL.appendingPathComponent(file.name)
                try? file.data.write(to: url, options: .atomic)
            }
        }
        #else
        let tempDir = FileManager.default.temporaryDirectory
        var urls: [URL] = []
        for file in files {
            let url = tempDir.appendingPathComponent(file.name)
            do {
                try file.data.write(to: url, options: .atomic)
                urls.append(url)
            } catch {
                // Skip failed writes silently
            }
        }
        guard !urls.isEmpty else { return }

        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}

