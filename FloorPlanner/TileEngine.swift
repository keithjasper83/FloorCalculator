//
//  TileEngine.swift
//  FloorPlanner
//
//  Layout engine for carpet tiles with grid-based placement
//

import Foundation

class TileEngine: LayoutEngine {
    
    func generateLayout(project: Project, useStock: Bool) -> LayoutResult {
        // Check for diagonal pattern
        if project.roomSettings.patternType == .diagonal && abs(project.roomSettings.angleDegrees) > 0.1 {
            let transform = LayoutTransform(room: project.roomSettings, angleDegrees: project.roomSettings.angleDegrees)
            let rotatedRoom = transform.rotatedRoom(from: project.roomSettings)

            var rotatedProject = project
            rotatedProject.roomSettings = rotatedRoom
            // Ensure pattern type is straight for the internal engine
            rotatedProject.roomSettings.patternType = .straight
            rotatedProject.roomSettings.angleDegrees = 0

            let result = generateLayoutInternal(project: rotatedProject, useStock: useStock)

            // Transform pieces back
            let transformedPieces = result.placedPieces.map { transform.transformBack($0) }

            var finalResult = result
            finalResult.placedPieces = transformedPieces
            return finalResult
        }

        return generateLayoutInternal(project: project, useStock: useStock)
    }

    private func generateLayoutInternal(project: Project, useStock: Bool) -> LayoutResult {
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
        
        // Count available stock and track prices
        var availableFullTiles = 0
        var availablePrices: [Double] = []

        if useStock && !project.stockItems.isEmpty {
            for item in project.stockItems {
                // Only count items that match tile size
                if abs(item.lengthMm - tileSize) < 1.0 && abs(item.widthMm - tileSize) < 1.0 {
                    availableFullTiles += item.quantity
                    // Add price for each individual tile
                    for _ in 0..<item.quantity {
                        availablePrices.append(item.pricePerUnit ?? 0.0)
                    }
                }
            }
            // Sort cheaper tiles first? Or consistent order.
            // Let's assume user wants to use stock regardless of price, but tracking cheapest first is a valid optimization.
            availablePrices.sort()
        }
        
        var placedPieces: [PlacedPiece] = []
        var cutRecords: [CutRecord] = []
        var edgeCutCount = 0
        var tilesUsed = 0
        var usedStockCost = 0.0

        // Calculate offset for room coordinates (for polygon check)
        var minX = 0.0
        var minY = 0.0
        if room.shape == .polygon {
             minX = room.polygonPoints.map { $0.x }.min() ?? 0
             minY = room.polygonPoints.map { $0.y }.min() ?? 0
        }
        let roomOriginX = minX + room.expansionGapMm
        let roomOriginY = minY + room.expansionGapMm
        
        // Place tiles in grid
        // Start from -1 to handle brick pattern left edge
        let startCol = -1
        // We might need an extra column for brick pattern right edge if offset pushes it over, but tilesAlongLength covers it mostly
        let endCol = tilesAlongLength

        for row in 0..<tilesAlongWidth {
            for col in startCol..<endCol {
                var rawX = Double(col) * tileSize
                let rawY = Double(row) * tileSize

                // Apply brick offset pattern if selected
                if settings.pattern == .brick && row % 2 == 1 {
                    rawX += tileSize / 2
                }
                
                // Calculate intersection with usable area rect to get actual dimensions
                let startX = max(0, rawX)
                let endX = min(usableLength, rawX + tileSize)
                let startY = max(0, rawY)
                let endY = min(usableWidth, rawY + tileSize)
                
                let placedLength = endX - startX
                let placedWidth = endY - startY

                // Skip if tile is effectively outside usable bounds
                if placedLength < 0.1 || placedWidth < 0.1 { continue }

                // Check if inside room polygon (using center of the visible piece)
                let centerX = startX + placedLength / 2
                let centerY = startY + placedWidth / 2

                let roomCheckX = roomOriginX + centerX
                let roomCheckY = roomOriginY + centerY

                if !room.contains(x: roomCheckX, y: roomCheckY) {
                    continue
                }
                
                // Determine rotation for quarter-turn pattern
                var rotation = 0.0
                if settings.orientation == .quarterTurn {
                    // Checkerboard pattern
                    rotation = ((row + col) % 2 == 0) ? 0.0 : 90.0
                }
                
                let isFullTile = (placedLength >= tileSize - 0.1) && (placedWidth >= tileSize - 0.1)
                let isCutTile = !isFullTile
                
                // Determine if this tile comes from stock or is needed
                let source: PlacedPiece.PieceSource
                let status: PlacedPiece.PieceStatus
                
                if tilesUsed < availableFullTiles {
                    source = .stock
                    status = .installed

                    // Consume price
                    if tilesUsed < availablePrices.count {
                        usedStockCost += availablePrices[tilesUsed]
                    }

                    tilesUsed += 1
                } else {
                    source = .needed
                    status = .needed
                }
                
                let label = status == .installed
                    ? "T\(placedPieces.count + 1)"
                    : "N\(placedPieces.count + 1)"
                
                let piece = PlacedPiece(
                    x: startX,
                    y: startY,
                    lengthMm: placedLength,
                    widthMm: placedWidth,
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
            for _ in 0..<unusedTiles {
                remainingPieces.append(RemainingPiece(
                    lengthMm: tileSize,
                    widthMm: tileSize,
                    source: .stock
                ))
            }
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
        var purchaseCost = 0.0

        let neededTiles = placedPieces.filter { $0.status == .needed }.count
        if neededTiles > 0 {
            let wasteFactor = 1.0 + (project.wasteFactor / 100.0)
            let neededWithWaste = Int(ceil(Double(neededTiles) * wasteFactor))
            
            var packsNeeded: Int?
            if let tilesPerBox = settings.tilesPerBox, tilesPerBox > 0 {
                packsNeeded = Int(ceil(Double(neededWithWaste) / Double(tilesPerBox)))
            }
            
            var estimatedCost: Double?
            if let defaultPrice = settings.defaultPricePerTile {
                let cost = defaultPrice * Double(neededWithWaste)
                estimatedCost = cost
                purchaseCost += cost
            }

            purchaseSuggestions.append(PurchaseSuggestion(
                unitLengthMm: tileSize,
                unitWidthMm: tileSize,
                quantityNeeded: neededWithWaste,
                packsNeeded: packsNeeded,
                estimatedCost: estimatedCost
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
            surplusAreaM2: surplusAreaM2,
            totalCost: usedStockCost + purchaseCost
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
            surplusAreaM2: 0,
            totalCost: 0
        )
    }
}
