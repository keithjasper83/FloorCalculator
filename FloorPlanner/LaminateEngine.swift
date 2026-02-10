//
//  LaminateEngine.swift
//  FloorPlanner
//
//  Layout engine for laminate planks with row-by-row placement
//

import Foundation

class LaminateEngine: LayoutEngine {
    
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
        guard let settings = project.laminateSettings else {
            return emptyResult()
        }
        
        let room = project.roomSettings
        let usableLength = room.usableLengthMm
        let usableWidth = room.usableWidthMm
        
        // Determine primary width
        let primaryWidth = determinePrimaryWidth(stockItems: project.stockItems, settings: settings)
        
        // Collect available pieces
        var availablePieces: [(length: Double, width: Double, source: PlacedPiece.PieceSource, price: Double?)] = []
        
        if useStock && !project.stockItems.isEmpty {
            for item in project.stockItems where item.widthMm == primaryWidth {
                for _ in 0..<item.quantity {
                    availablePieces.append((item.lengthMm, item.widthMm, .stock, item.pricePerUnit))
                }
            }
        }
        
        // Sort by length descending
        availablePieces.sort { $0.length > $1.length }
        
        var placedPieces: [PlacedPiece] = []
        var cutRecords: [CutRecord] = []
        var offcuts: [(length: Double, width: Double)] = []
        var usedStockCost = 0.0
        var rowIndex = 0
        
        // Determine row direction
        let (rowLength, rowCount) = settings.plankDirection == .alongLength
            ? (usableLength, Int(ceil(usableWidth / primaryWidth)))
            : (usableWidth, Int(ceil(usableLength / primaryWidth)))
        
        var currentY = 0.0
        var lastRowStartOffset = 0.0
        
        // Place rows
        for row in 0..<rowCount {
            let rowY = currentY
            
            // Check if we have space for this row
            let remainingWidth = settings.plankDirection == .alongLength
                ? (usableWidth - rowY)
                : (usableLength - rowY)
            
            if remainingWidth < primaryWidth * 0.1 {
                break
            }
            
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
            let segments = getSegments(room: room, rowCenterY: rowY + primaryWidth/2)
            
            // Fill each segment
            for (segStart, segEnd) in segments {
                var currentX = segStart
                
                while currentX < segEnd {
                    // Determine target length for this piece based on pattern alignment
                    // Pattern aligns to rowStartOffset relative to 0

                    let k = floor((currentX - rowStartOffset) / settings.defaultPlankLengthMm) + 1
                    let nextJointX = rowStartOffset + k * settings.defaultPlankLengthMm

                    let distToJoint = nextJointX - currentX
                    let distToEnd = segEnd - currentX

                    let targetLength = min(distToJoint, distToEnd)
                    if targetLength < 1.0 {
                        currentX += 1.0
                        continue
                    }

                    // Try to find a piece that fits targetLength
                    // We need a piece of at least targetLength.
                    // If we use stock (typically defaultPlankLength), we cut it down.
                    // If we use offcut, it must be >= targetLength.

                    var pieceIndex = -1
                    var selectedPiece: (length: Double, width: Double, source: PlacedPiece.PieceSource, price: Double?)?

                    // First try offcuts
                    for (index, offcut) in offcuts.enumerated() {
                        if offcut.length >= targetLength {
                            pieceIndex = -1000 - index
                            // Offcuts are free (cost attributed to parent)
                            selectedPiece = (offcut.length, offcut.width, .offcut, nil)
                            break
                        }
                    }
                    
                    // Then try available stock
                    if selectedPiece == nil {
                        for (index, piece) in availablePieces.enumerated() {
                            if piece.length >= targetLength {
                                pieceIndex = index
                                selectedPiece = piece
                                break
                            }
                        }
                    }

                    guard var piece = selectedPiece else {
                        // No stock available - use NEEDED pieces
                        let label = "N\(placedPieces.count + 1)"
                        let placedPiece = PlacedPiece(
                            x: currentX,
                            y: rowY,
                            lengthMm: targetLength,
                            widthMm: primaryWidth,
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
                    if pieceIndex >= 0 {
                        availablePieces.remove(at: pieceIndex)
                        if let price = piece.price {
                            usedStockCost += price
                        }
                    } else {
                        let offcutIndex = -pieceIndex - 1000
                        offcuts.remove(at: offcutIndex)
                    }

                    // Cut logic
                    // We have 'piece' of length 'piece.length'. We need 'targetLength'.
                    // Cut piece to targetLength. Remainder is offcut.

                    var cutType: CutRecord.LaminateCutType? = nil
                    if abs(currentX - segStart) < 1.0 {
                        cutType = .startCut
                    } else if abs(currentX + targetLength - segEnd) < 1.0 {
                        cutType = .endCut
                    }

                    if piece.length > targetLength + 1.0 { // Tolerance
                        let offcutLength = piece.length - targetLength
                        if offcutLength >= settings.minOffcutLengthMm {
                            offcuts.append((offcutLength, piece.width))
                        }
                        
                        cutRecords.append(CutRecord(
                            materialType: .laminate,
                            row: row,
                            cutType: cutType ?? .endCut, // Middle cuts are rare unless using long stock? Usually we cut to fit joint or wall.
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
            
            currentY += primaryWidth
            rowIndex += 1
        }
        
        // Build remaining pieces list
        var remainingPieces: [RemainingPiece] = []
        for piece in availablePieces {
            remainingPieces.append(RemainingPiece(
                lengthMm: piece.length,
                widthMm: piece.width,
                source: piece.source
            ))
        }
        for offcut in offcuts {
            if offcut.length >= settings.minOffcutLengthMm {
                remainingPieces.append(RemainingPiece(
                    lengthMm: offcut.length,
                    widthMm: offcut.width,
                    source: .offcut
                ))
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
            // But if scanline is exactly on edge, we might have issues.
            // Standard ray casting rule: (p1.y <= Y < p2.y) or (p2.y <= Y < p1.y)
            if (p1.y <= roomY && p2.y > roomY) || (p2.y <= roomY && p1.y > roomY) {
                // Calculate x
                // x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
                // Avoid division by zero (guaranteed by condition p1.y != p2.y)
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
            // Bounding box for usable area is 0 to usableLength
            let validStart = max(0, layoutStart)
            let validEnd = min(room.usableLengthMm, layoutEnd)

            if validEnd > validStart {
                segments.append((validStart, validEnd))
            }
            i += 2
        }

        // Fallback if no intersections found but we are within Y bounds of the polygon?
        // If scanline misses (e.g. gap), segments is empty. Correct.
        // If rectangular mode fell through (shouldn't happen), return bounds.

        // If segments is empty but we expect something?
        // For polygon, if we are outside the polygon, segments is empty. Correct.

        return segments
    }
}
