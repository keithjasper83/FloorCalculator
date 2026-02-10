//
//  TileEngine.swift
//  FloorPlanner
//
//  Layout engine for carpet tiles with grid-based placement
//

import Foundation

class TileEngine: LayoutEngine {
    
    func generateLayout(project: Project, useStock: Bool) -> LayoutResult {
        guard let settings = project.tileSettings else {
            return emptyResult()
        }
        
        let room = project.roomSettings
        let usableLength = room.usableLengthMm
        let usableWidth = room.usableWidthMm
        let tileSize = settings.tileSizeMm
        
        // Calculate grid dimensions
        let tilesAlongLength = Int(ceil(usableLength / tileSize))
        let tilesAlongWidth = Int(ceil(usableWidth / tileSize))
        let totalTilesNeeded = tilesAlongLength * tilesAlongWidth
        
        // Count available stock
        var availableFullTiles = 0
        if useStock && !project.stockItems.isEmpty {
            for item in project.stockItems {
                // Only count items that match tile size
                if abs(item.lengthMm - tileSize) < 1.0 && abs(item.widthMm - tileSize) < 1.0 {
                    availableFullTiles += item.quantity
                }
            }
        }
        
        var placedPieces: [PlacedPiece] = []
        var cutRecords: [CutRecord] = []
        var edgeCutCount = 0
        var tilesUsed = 0
        
        // Place tiles in grid
        for row in 0..<tilesAlongWidth {
            for col in 0..<tilesAlongLength {
                let x = Double(col) * tileSize
                let y = Double(row) * tileSize
                
                // Calculate actual tile dimensions (may be cut at edges)
                let remainingLength = usableLength - x
                let remainingWidth = usableWidth - y
                let actualLength = min(tileSize, remainingLength)
                let actualWidth = min(tileSize, remainingWidth)
                
                let isFullTile = (actualLength >= tileSize - 0.1) && (actualWidth >= tileSize - 0.1)
                let isCutTile = !isFullTile
                
                // Determine rotation for quarter-turn pattern
                var rotation = 0.0
                if settings.orientation == .quarterTurn {
                    // Checkerboard pattern
                    rotation = ((row + col) % 2 == 0) ? 0.0 : 90.0
                }
                
                // Apply brick offset pattern if selected
                var offsetX = x
                if settings.pattern == .brick && row % 2 == 1 {
                    offsetX += tileSize / 2
                    // Check if offset pushes us out of bounds
                    if offsetX + actualLength > usableLength {
                        continue // Skip this tile in brick pattern
                    }
                }
                
                // Determine if this tile comes from stock or is needed
                let source: PlacedPiece.PieceSource
                let status: PlacedPiece.PieceStatus
                
                if tilesUsed < availableFullTiles {
                    source = .stock
                    status = .installed
                    tilesUsed += 1
                } else {
                    source = .needed
                    status = .needed
                }
                
                let label = status == .installed
                    ? "T\(placedPieces.count + 1)"
                    : "N\(placedPieces.count + 1)"
                
                let piece = PlacedPiece(
                    x: offsetX,
                    y: y,
                    lengthMm: actualLength,
                    widthMm: actualWidth,
                    label: label,
                    source: source,
                    status: status,
                    rotation: rotation
                )
                placedPieces.append(piece)
                
                // Track edge cuts
                if isCutTile {
                    edgeCutCount += 1
                }
            }
        }
        
        // Add cut record for edge tiles
        if edgeCutCount > 0 {
            cutRecords.append(CutRecord(
                materialType: .carpetTile,
                row: nil,
                cutType: nil,
                fromLengthMm: nil,
                cutToMm: nil,
                offcutLengthMm: nil,
                widthMm: nil,
                edgeCutCount: edgeCutCount,
                cutDimensionsMm: "Edge tiles (various dimensions)"
            ))
        }
        
        // Calculate remaining pieces
        var remainingPieces: [RemainingPiece] = []
        let unusedTiles = availableFullTiles - tilesUsed
        if unusedTiles > 0 {
            remainingPieces.append(RemainingPiece(
                lengthMm: tileSize,
                widthMm: tileSize,
                source: .stock
            ))
        }
        
        // If reuse edge offcuts is enabled, calculate saved offcuts
        // (simplified - not fully implemented in v1)
        
        // Calculate areas
        let installedAreaM2 = LayoutUtilities.calculateInstalledArea(pieces: placedPieces)
        let neededAreaM2 = LayoutUtilities.calculateNeededArea(pieces: placedPieces)
        
        // Waste calculation for tiles: edge cut waste
        // Estimate: each cut tile wastes approximately half a tile's area
        let cutTileWasteM2 = Double(edgeCutCount) * (tileSize * tileSize / 2.0) / 1_000_000
        let wasteAreaM2 = cutTileWasteM2 + LayoutUtilities.calculateWasteArea(remainingPieces: remainingPieces)
        
        let stockAreaM2 = useStock ? LayoutUtilities.calculateStockArea(stockItems: project.stockItems) : 0
        let surplusAreaM2 = max(0, stockAreaM2 - installedAreaM2 - wasteAreaM2)
        
        // Generate purchase suggestions
        var purchaseSuggestions: [PurchaseSuggestion] = []
        let neededTiles = placedPieces.filter { $0.status == .needed }.count
        if neededTiles > 0 {
            let wasteFactor = 1.0 + (project.wasteFactor / 100.0)
            let neededWithWaste = Int(ceil(Double(neededTiles) * wasteFactor))
            
            var packsNeeded: Int?
            if let tilesPerBox = settings.tilesPerBox, tilesPerBox > 0 {
                packsNeeded = Int(ceil(Double(neededWithWaste) / Double(tilesPerBox)))
            }
            
            purchaseSuggestions.append(PurchaseSuggestion(
                unitLengthMm: tileSize,
                unitWidthMm: tileSize,
                quantityNeeded: neededWithWaste,
                packsNeeded: packsNeeded
            ))
        }
        
        return LayoutResult(
            placedPieces: placedPieces,
            cutRecords: cutRecords,
            remainingPieces: remainingPieces,
            purchaseSuggestions: purchaseSuggestions,
            installedAreaM2: installedAreaM2,
            neededAreaM2: neededAreaM2,
            wasteAreaM2: wasteAreaM2,
            surplusAreaM2: surplusAreaM2
        )
    }
    
    private func emptyResult() -> LayoutResult {
        return LayoutResult(
            placedPieces: [],
            cutRecords: [],
            remainingPieces: [],
            purchaseSuggestions: [],
            installedAreaM2: 0,
            neededAreaM2: 0,
            wasteAreaM2: 0,
            surplusAreaM2: 0
        )
    }
}
