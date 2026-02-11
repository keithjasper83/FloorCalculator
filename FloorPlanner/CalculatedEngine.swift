//
//  CalculatedEngine.swift
//  FloorPlanner
//
//  Engine for continuous materials like paint and concrete
//

import Foundation

class CalculatedEngine: LayoutEngine {

    // Properties to define the material being calculated
    // In a full implementation, these would be passed in or retrieved from the active Layer
    var material: Material
    var thicknessMm: Double

    init(material: Material = .concrete, thicknessMm: Double = 0.0) {
        self.material = material
        self.thicknessMm = thicknessMm
    }

    func generateLayout(project: Project, useStock: Bool) -> LayoutResult {
        let room = project.roomSettings
        let areaM2 = room.usableAreaM2

        var quantityNeeded: Double = 0
        var unitName = material.unitName ?? "Units"
        var volumeM3: Double = 0

        // Calculate based on type
        if material.category == .liquid || material.category == .structural {
             if let coverage = material.coveragePerUnit, coverage > 0 {
                 // Coverage based (e.g., Paint: 10m2/L)
                 quantityNeeded = areaM2 / coverage
             } else if material.calculationType == .continuous {
                 // Volume based (e.g., Concrete)
                 // If thickness is provided (or default)
                 let depth = thicknessMm > 0 ? thicknessMm : (material.defaultThicknessMm ?? 0)
                 // Area (m2) * Depth (mm -> m) = Volume (m3)
                 volumeM3 = areaM2 * (depth / 1000.0)
                 quantityNeeded = volumeM3

                 // If unit is not m3, we might need conversion, but let's assume m3 for structural
                 if material.unitName == nil {
                     unitName = "m³"
                 }
             }
        }

        // Calculate Cost
        var estimatedCost: Double?
        if let price = material.pricePerUnit {
            estimatedCost = quantityNeeded * price
        }

        // Generate Suggestion
        // For continuous materials, we don't have "packs" usually, but maybe "buckets"
        // For now, simple quantity
        let suggestion = PurchaseSuggestion(
            id: UUID(),
            unitLengthMm: 0,
            unitWidthMm: 0,
            quantityNeeded: Int(ceil(quantityNeeded)), // Integer quantity for now (e.g. buckets), but continuous might need Double
            packsNeeded: nil,
            estimatedCost: estimatedCost
        )
        // Note: PurchaseSuggestion uses Int for quantity. For Volume, this is imprecise.
        // We might need to refactor PurchaseSuggestion to support Double quantity or just store rounded up integer.

        return LayoutResult(
            placedPieces: [], // No individual pieces for continuous
            cutRecords: [],
            remainingPieces: [],
            purchaseSuggestions: [suggestion],
            installedAreaM2: areaM2,
            neededAreaM2: 0, // We assume we just buy what's needed
            wasteAreaM2: 0, // Waste is implicit in coverage or extra purchase
            surplusAreaM2: 0,
            totalCost: estimatedCost ?? 0
        )
    }
}
