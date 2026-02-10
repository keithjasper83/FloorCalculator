//
//  LayoutEngine.swift
//  FloorPlanner
//
//  Protocol and common functionality for layout engines
//

import Foundation

protocol LayoutEngine {
    func generateLayout(
        project: Project,
        useStock: Bool
    ) -> LayoutResult
}

// MARK: - Common Layout Utilities

struct LayoutUtilities {
    
    /// Calculate stock area from stock items
    static func calculateStockArea(stockItems: [StockItem]) -> Double {
        stockItems.reduce(0.0) { $0 + $1.areaM2 }
    }
    
    /// Calculate installed area from placed pieces
    static func calculateInstalledArea(pieces: [PlacedPiece]) -> Double {
        pieces
            .filter { $0.status == .installed }
            .reduce(0.0) { $0 + $1.areaM2 }
    }
    
    /// Calculate needed area from placed pieces
    static func calculateNeededArea(pieces: [PlacedPiece]) -> Double {
        pieces
            .filter { $0.status == .needed }
            .reduce(0.0) { $0 + $1.areaM2 }
    }
    
    /// Calculate waste area from remaining pieces
    static func calculateWasteArea(remainingPieces: [RemainingPiece]) -> Double {
        remainingPieces.reduce(0.0) { $0 + $1.areaM2 }
    }
    
    /// Calculate surplus or shortfall
    static func calculateSurplus(
        stockAreaM2: Double,
        installedAreaM2: Double,
        wasteAreaM2: Double
    ) -> Double {
        stockAreaM2 - installedAreaM2 - wasteAreaM2
    }
    
    /// Check if two pieces overlap
    static func overlaps(
        piece1: (x: Double, y: Double, length: Double, width: Double),
        piece2: (x: Double, y: Double, length: Double, width: Double)
    ) -> Bool {
        let x1End = piece1.x + piece1.length
        let y1End = piece1.y + piece1.width
        let x2End = piece2.x + piece2.length
        let y2End = piece2.y + piece2.width
        
        return !(piece1.x >= x2End || x1End <= piece2.x ||
                piece1.y >= y2End || y1End <= piece2.y)
    }
}
