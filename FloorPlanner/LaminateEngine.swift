//
//  LaminateEngine.swift
//  FloorPlanner
//
//  Layout engine for laminate planks with row-by-row placement
//

import Foundation

class LaminateEngine: LayoutEngine {
    
    func generateLayout(project: Project, useStock: Bool) -> LayoutResult {
        return generateLayoutWithRotation(project: project) { proj in
            self.generateLayoutInternal(project: proj, useStock: useStock)
        }
    }

    private func generateLayoutInternal(project: Project, useStock: Bool) -> LayoutResult {
        guard let settings = project.laminateSettings else {
            return emptyResult()
        }
        
        let room = project.roomSettings
        let usableLength = room.usableLengthMm
        let usableWidth = room.usableWidthMm
        
        // Determine primary width (used as fallback for "needed" pieces)
        let primaryWidth = determinePrimaryWidth(stockItems: project.stockItems, settings: settings)
        
        // Group stock pieces by width for O(1) access
        var availableByWidth: [Double: [(length: Double, price: Double?)]] = [:]
        var nextStockIndexByWidth: [Double: Int] = [:]
        
        if useStock && !project.stockItems.isEmpty {
            for item in project.stockItems {
                let piece = (length: item.lengthMm, price: item.pricePerUnit)
                for _ in 0..<item.quantity {
                    availableByWidth[item.widthMm, default: []].append(piece)
                }
            }

            // Sort each width group by length descending
            for width in availableByWidth.keys {
                if var pieces = availableByWidth[width] {
                    pieces.sort { $0.length > $1.length }
                    availableByWidth[width] = pieces
                }
                nextStockIndexByWidth[width] = 0
            }
        }
        
        var placedPieces: [PlacedPiece] = []
        var cutRecords: [CutRecord] = []
        var offcutsByWidth: [Double: [Double]] = [:]
        var usedStockCost = 0.0
        
        // Determine direction: roomDepth is the dimension we stack rows across
        let roomDepth = settings.plankDirection == .alongLength ? usableWidth : usableLength
        let rowLength = settings.plankDirection == .alongLength ? usableLength : usableWidth

        var currentY = 0.0
        var lastRowStartOffset = 0.0
        var row = 0

        // Place rows dynamically; row width is determined from available stock at each iteration
        while currentY < roomDepth - Constants.geometryToleranceMm {
            let remaining = roomDepth - currentY

            // Pick the widest board width available that fits the remaining depth.
            // Falls back to defaultPlankWidthMm (capped at remaining) when no stock is left.
            // We get both the original width (for lookups) and the ripped width (for layout).
            let widthResult = largestFittingWidth(
                remaining: remaining,
                availableByWidth: availableByWidth,
                nextStockIndexByWidth: nextStockIndexByWidth,
                offcutsByWidth: offcutsByWidth,
                defaultWidth: primaryWidth
            )

            let originalWidth = widthResult.original
            let rowWidth = widthResult.ripped

            if rowWidth < Constants.snapToleranceMm { break }

            let rowY = currentY
            
            // Calculate row start offset for stagger
            var rowStartOffset = 0.0
            if row > 0 {
                // Ensure minimum stagger from previous row
                let minNextOffset = lastRowStartOffset + settings.minStaggerMm
                let maxNextOffset = lastRowStartOffset + (rowLength / 2)
                rowStartOffset = min(minNextOffset, maxNextOffset)
                
                // If we exceed row length, wrap around
                if rowStartOffset >= rowLength {
                    rowStartOffset = settings.minStaggerMm
                }
            }
            
            lastRowStartOffset = rowStartOffset
            
            // Get valid segments for this row (intersects with polygon)
            let segments = getSegments(room: room, rowCenterY: rowY + rowWidth / 2)
            
            // Fill each segment
            for (segStart, segEnd) in segments {
                var currentX = segStart
                
                while currentX < segEnd {
                    // Determine target length for this piece based on pattern alignment
                    let k = floor((currentX - rowStartOffset) / settings.defaultPlankLengthMm) + 1
                    let nextJointX = rowStartOffset + k * settings.defaultPlankLengthMm

                    let distToJoint = nextJointX - currentX
                    let distToEnd = segEnd - currentX

                    let targetLength = min(distToJoint, distToEnd)
                    if targetLength < Constants.snapToleranceMm {
                        currentX += Constants.snapToleranceMm
                        continue
                    }

                    // Try to find a piece matching rowWidth and long enough
                    var selectedPiece: (length: Double, width: Double, source: PlacedPiece.PieceSource, price: Double?)?
                    var selectedOffcutIndex: Int?

                    // First try offcuts (must match originalWidth)
                    if let offcutsForWidth = offcutsByWidth[originalWidth] {
                        for (index, offcutLength) in offcutsForWidth.enumerated() {
                            if offcutLength >= targetLength {
                                selectedOffcutIndex = index
                                selectedPiece = (offcutLength, originalWidth, .offcut, nil)
                                break
                            }
                        }
                    }
                    
                    // Then try available stock (must match originalWidth)
                    if selectedPiece == nil {
                        if let pieces = availableByWidth[originalWidth] {
                            let nextIdx = nextStockIndexByWidth[originalWidth, default: 0]
                            if nextIdx < pieces.count {
                                let piece = pieces[nextIdx]
                                if piece.length >= targetLength {
                                    selectedPiece = (piece.length, originalWidth, .stock, piece.price)
                                }
                            }
                        }
                    }

                    guard let piece = selectedPiece else {
                        // No stock available - use NEEDED pieces
                        let label = "N\(placedPieces.count + 1)"
                        let placedPiece = PlacedPiece(
                            x: currentX,
                            y: rowY,
                            lengthMm: targetLength,
                            widthMm: rowWidth,
                            label: label,
                            source: .needed,
                            status: .needed,
                            rotation: 0
                        )
                        placedPieces.append(placedPiece)
                        currentX += targetLength
                        continue
                    }

                    // Remove piece from available or offcuts
                    if let offcutIdx = selectedOffcutIndex {
                        offcutsByWidth[originalWidth]?.remove(at: offcutIdx)
                    } else if piece.source == .stock {
                        nextStockIndexByWidth[originalWidth, default: 0] += 1
                        if let price = piece.price {
                            usedStockCost += price
                        }
                    }

                    // Cut logic
                    var cutType: CutRecord.LaminateCutType? = nil
                    if abs(currentX - segStart) < Constants.geometryToleranceMm {
                        cutType = .startCut
                    } else if abs(currentX + targetLength - segEnd) < Constants.geometryToleranceMm {
                        cutType = .endCut
                    }

                    if piece.length > targetLength + Constants.snapToleranceMm { // Tolerance
                        let offcutLength = piece.length - targetLength
                        if offcutLength >= settings.minOffcutLengthMm {
                            offcutsByWidth[piece.width, default: []].append(offcutLength)
                        }
                        
                        cutRecords.append(CutRecord(
                            materialType: .laminate,
                            row: row,
                            cutType: cutType ?? .endCut,
                            fromLengthMm: piece.length,
                            cutToMm: targetLength,
                            offcutLengthMm: offcutLength,
                            widthMm: piece.width
                        ))
                    }
                    
                    let label = piece.source == .offcut ? "O\(placedPieces.count + 1)" : "S\(placedPieces.count + 1)"

                    let placedPiece = PlacedPiece(
                        x: currentX,
                        y: rowY,
                        lengthMm: targetLength,
                        widthMm: piece.width,
                        label: label,
                        source: piece.source,
                        status: .installed,
                        rotation: 0
                    )
                    placedPieces.append(placedPiece)
                    currentX += targetLength
                }
            }
            
            currentY += rowWidth
            row += 1
        }
        
        // Build remaining pieces list
        var remainingPieces: [RemainingPiece] = []
        for (width, pieces) in availableByWidth {
            let nextIdx = nextStockIndexByWidth[width, default: 0]
            if nextIdx < pieces.count {
                for i in nextIdx..<pieces.count {
                    let piece = pieces[i]
                    remainingPieces.append(RemainingPiece(
                        lengthMm: piece.length,
                        widthMm: width,
                        source: .stock
                    ))
                }
            }
        }
        for (width, lengths) in offcutsByWidth {
            for length in lengths {
                if length >= settings.minOffcutLengthMm {
                    remainingPieces.append(RemainingPiece(
                        lengthMm: length,
                        widthMm: width,
                        source: .offcut
                    ))
                }
            }
        }
        
        // Calculate areas
        let installedAreaM2 = LayoutUtilities.calculateInstalledArea(pieces: placedPieces)
        let neededAreaM2 = LayoutUtilities.calculateNeededArea(pieces: placedPieces)
        let wasteAreaM2 = LayoutUtilities.calculateWasteArea(remainingPieces: remainingPieces)
        
        let stockAreaM2 = useStock ? LayoutUtilities.calculateStockArea(stockItems: project.stockItems) : 0
        let surplusAreaM2 = max(0, stockAreaM2 - installedAreaM2 - wasteAreaM2)
        
        // Generate purchase suggestions
        var purchaseSuggestions: [PurchaseSuggestion] = []
        var purchaseCost = 0.0

        if neededAreaM2 > 0 {
            let neededCount = placedPieces.filter { $0.status == .needed }.count
            if neededCount > 0 {
                var estimatedCost: Double?
                if let defaultPrice = settings.defaultPricePerPlank {
                    let cost = defaultPrice * Double(neededCount)
                    estimatedCost = cost
                    purchaseCost += cost
                }

                purchaseSuggestions.append(PurchaseSuggestion(
                    unitLengthMm: settings.defaultPlankLengthMm,
                    unitWidthMm: primaryWidth,
                    quantityNeeded: neededCount,
                    packsNeeded: nil,
                    estimatedCost: estimatedCost
                ))
            }
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
    
    private func determinePrimaryWidth(stockItems: [StockItem], settings: LaminateSettings) -> Double {
        if stockItems.isEmpty {
            return settings.defaultPlankWidthMm
        }
        
        // Find most abundant width
        var widthCounts: [Double: Int] = [:]
        for item in stockItems {
            widthCounts[item.widthMm, default: 0] += item.quantity
        }
        
        if let primary = widthCounts.max(by: { $0.value < $1.value }) {
            return primary.key
        }
        
        return settings.defaultPlankWidthMm
    }
    
    /// Returns the largest board width available in stock/offcuts that fits within `remaining`.
    /// Returns both the original width (for lookups) and the ripped width (capped at `remaining`).
    /// Falls back to `primaryWidth` when no stock is available.
    private func largestFittingWidth(
        remaining: Double,
        availableByWidth: [Double: [(length: Double, price: Double?)]],
        nextStockIndexByWidth: [Double: Int],
        offcutsByWidth: [Double: [Double]],
        defaultWidth: Double
    ) -> (original: Double, ripped: Double) {
        var maxFitting = 0.0

        // Check stock widths
        for (width, pieces) in availableByWidth {
            let nextIdx = nextStockIndexByWidth[width, default: 0]
            if nextIdx < pieces.count {
                if width <= remaining + Constants.geometryToleranceMm && width > maxFitting {
                    maxFitting = width
                }
            }
        }

        // Check offcut widths
        for (width, lengths) in offcutsByWidth {
            if !lengths.isEmpty {
                if width <= remaining + Constants.geometryToleranceMm && width > maxFitting {
                    maxFitting = width
                }
            }
        }

        if maxFitting > Constants.geometryToleranceMm {
            return (original: maxFitting, ripped: min(maxFitting, remaining))
        }
        // No stock available; use default width (capped at remaining space)
        return (original: defaultWidth, ripped: min(defaultWidth, remaining))
    }

    // Helper to find valid segments for a row in a polygon room
    private func getSegments(room: RoomSettings, rowCenterY: Double) -> [(Double, Double)] {
        // If rectangular, just return full width
        if room.shape == .rectangular {
            return [(0.0, room.usableLengthMm)]
        }

        guard !room.polygonPoints.isEmpty else {
             return [(0.0, room.usableLengthMm)]
        }

        // Calculate offset for room coordinates
        let minX = room.polygonPoints.map { $0.x }.min() ?? 0
        let minY = room.polygonPoints.map { $0.y }.min() ?? 0

        // Convert layout Y to room Y
        // Layout origin is at (minX + gap, minY + gap) relative to polygon origin
        let roomY = rowCenterY + minY + room.expansionGapMm

        var intersections: [Double] = []
        let points = room.polygonPoints
        let n = points.count

        for i in 0..<n {
            let j = (i + 1) % n
            let p1 = points[i]
            let p2 = points[j]

            // Check edge intersection with y = roomY
            // Handle horizontal edges: skip them (they don't cross scanline, they ARE scanline)
            if (p1.y <= roomY && p2.y > roomY) || (p2.y <= roomY && p1.y > roomY) {
                // Calculate x
                // x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
                let t = (roomY - p1.y) / (p2.y - p1.y)
                let x = p1.x + t * (p2.x - p1.x)
                intersections.append(x)
            }
        }

        intersections.sort()

        var segments: [(Double, Double)] = []
        var i = 0
        while i < intersections.count - 1 {
            let start = intersections[i]
            let end = intersections[i+1]

            // Convert back to layout coordinates
            // Layout X = Room X - minX - gap
            let layoutStart = start - minX - room.expansionGapMm
            let layoutEnd = end - minX - room.expansionGapMm

            // Clip to bounding box just in case
            let validStart = max(0, layoutStart)
            let validEnd = min(room.usableLengthMm, layoutEnd)

            if validEnd > validStart {
                segments.append((validStart, validEnd))
            }
            i += 2
        }

        return segments
    }
}

