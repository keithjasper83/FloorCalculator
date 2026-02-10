//
//  LaminateEngine.swift
//  FloorPlanner
//
//  Layout engine for laminate planks with row-by-row placement
//

import Foundation

class LaminateEngine: LayoutEngine {
    
    func generateLayout(project: Project, useStock: Bool) -> LayoutResult {
        guard let settings = project.laminateSettings else {
            return emptyResult()
        }
        
        let room = project.roomSettings
        let usableLength = room.usableLengthMm
        let usableWidth = room.usableWidthMm
        
        // Determine primary width
        let primaryWidth = determinePrimaryWidth(stockItems: project.stockItems, settings: settings)
        
        // Collect available pieces
        var availablePieces: [(length: Double, width: Double, source: PlacedPiece.PieceSource)] = []
        
        if useStock && !project.stockItems.isEmpty {
            for item in project.stockItems where item.widthMm == primaryWidth {
                for _ in 0..<item.quantity {
                    availablePieces.append((item.lengthMm, item.widthMm, .stock))
                }
            }
        }
        
        // Sort by length descending
        availablePieces.sort { $0.length > $1.length }
        
        var placedPieces: [PlacedPiece] = []
        var cutRecords: [CutRecord] = []
        var offcuts: [(length: Double, width: Double)] = []
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
            
            // Place planks in this row
            var currentX = rowStartOffset
            var needsStartCut = rowStartOffset > 0.0
            
            while currentX < rowLength {
                let remainingLength = rowLength - currentX
                
                // Try to find a piece that fits
                var pieceIndex = -1
                var selectedPiece: (length: Double, width: Double, source: PlacedPiece.PieceSource)?
                
                // First try offcuts
                for (index, offcut) in offcuts.enumerated() {
                    if offcut.length >= settings.minOffcutLengthMm && offcut.length <= remainingLength + 1.0 {
                        pieceIndex = -1000 - index // negative to identify as offcut
                        selectedPiece = (offcut.length, offcut.width, .offcut)
                        break
                    }
                }
                
                // Then try available stock
                if selectedPiece == nil {
                    for (index, piece) in availablePieces.enumerated() {
                        pieceIndex = index
                        selectedPiece = piece
                        break
                    }
                }
                
                guard var piece = selectedPiece else {
                    // No stock available - use NEEDED pieces
                    let neededLength = min(settings.defaultPlankLengthMm, remainingLength)
                    let label = "N\(placedPieces.count + 1)"
                    
                    let placedPiece = PlacedPiece(
                        x: currentX,
                        y: rowY,
                        lengthMm: neededLength,
                        widthMm: primaryWidth,
                        label: label,
                        source: .needed,
                        status: .needed,
                        rotation: 0
                    )
                    placedPieces.append(placedPiece)
                    currentX += neededLength
                    continue
                }
                
                // Remove piece from available or offcuts
                if pieceIndex >= 0 {
                    availablePieces.remove(at: pieceIndex)
                } else {
                    let offcutIndex = -pieceIndex - 1000
                    offcuts.remove(at: offcutIndex)
                }
                
                // Handle start cut
                if needsStartCut && rowStartOffset > 0 {
                    let cutLength = rowStartOffset
                    if piece.length > cutLength + settings.minOffcutLengthMm {
                        // Create offcut
                        let offcutLength = piece.length - cutLength
                        if offcutLength >= settings.minOffcutLengthMm {
                            offcuts.append((offcutLength, piece.width))
                        }
                        
                        cutRecords.append(CutRecord(
                            materialType: .laminate,
                            row: row,
                            cutType: .startCut,
                            fromLengthMm: piece.length,
                            cutToMm: cutLength,
                            offcutLengthMm: offcutLength,
                            widthMm: piece.width
                        ))
                        
                        piece.length = cutLength
                    }
                    needsStartCut = false
                }
                
                // Check if piece needs end cut
                let actualLength: Double
                if piece.length > remainingLength {
                    actualLength = remainingLength
                    let offcutLength = piece.length - remainingLength
                    if offcutLength >= settings.minOffcutLengthMm {
                        offcuts.append((offcutLength, piece.width))
                    }
                    
                    cutRecords.append(CutRecord(
                        materialType: .laminate,
                        row: row,
                        cutType: .endCut,
                        fromLengthMm: piece.length,
                        cutToMm: remainingLength,
                        offcutLengthMm: offcutLength,
                        widthMm: piece.width
                    ))
                } else {
                    actualLength = piece.length
                }
                
                let label = piece.source == .offcut ? "O\(placedPieces.count + 1)" : "S\(placedPieces.count + 1)"
                
                let placedPiece = PlacedPiece(
                    x: currentX,
                    y: rowY,
                    lengthMm: actualLength,
                    widthMm: piece.width,
                    label: label,
                    source: piece.source,
                    status: .installed,
                    rotation: 0
                )
                placedPieces.append(placedPiece)
                currentX += actualLength
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
        if neededAreaM2 > 0 {
            let neededCount = placedPieces.filter { $0.status == .needed }.count
            if neededCount > 0 {
                purchaseSuggestions.append(PurchaseSuggestion(
                    unitLengthMm: settings.defaultPlankLengthMm,
                    unitWidthMm: primaryWidth,
                    quantityNeeded: neededCount,
                    packsNeeded: nil
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
            surplusAreaM2: surplusAreaM2
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
