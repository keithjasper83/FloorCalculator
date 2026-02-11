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

// MARK: - Layout Engine Extension

extension LayoutEngine {
    /// Returns an empty layout result
    func emptyResult() -> LayoutResult {
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

    /// Handles rotation for diagonal layouts by transforming the room, running the closure, and transforming back
    func generateLayoutWithRotation(
        project: Project,
        performLayout: (Project) -> LayoutResult
    ) -> LayoutResult {
        // Check for diagonal pattern
        if project.roomSettings.patternType == .diagonal && abs(project.roomSettings.angleDegrees) > Constants.geometryToleranceMm {
            let transform = LayoutTransform(room: project.roomSettings, angleDegrees: project.roomSettings.angleDegrees)
            let rotatedRoom = transform.rotatedRoom(from: project.roomSettings)

            var rotatedProject = project
            rotatedProject.roomSettings = rotatedRoom
            // Ensure pattern type is straight for the internal engine
            rotatedProject.roomSettings.patternType = .straight
            rotatedProject.roomSettings.angleDegrees = 0

            let result = performLayout(rotatedProject)

            // Transform pieces back
            let transformedPieces = result.placedPieces.map { transform.transformBack($0) }

            var finalResult = result
            finalResult.placedPieces = transformedPieces
            return finalResult
        }

        return performLayout(project)
    }
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

// MARK: - Layout Transform (Diagonal Mode)

struct LayoutTransform {
    let angle: Double // radians
    let offset: (dx: Double, dy: Double) // Shift to make coordinates positive

    init(room: RoomSettings, angleDegrees: Double) {
        self.angle = angleDegrees * .pi / 180.0

        // Compute bounding box of rotated points
        let points = room.effectivePolygonPoints
        let cosA = cos(-angle)
        let sinA = sin(-angle)

        var minX = Double.infinity
        var minY = Double.infinity

        for p in points {
            let rx = p.x * cosA - p.y * sinA
            let ry = p.x * sinA + p.y * cosA
            if rx < minX { minX = rx }
            if ry < minY { minY = ry }
        }

        if minX == Double.infinity { minX = 0 }
        if minY == Double.infinity { minY = 0 }

        self.offset = (dx: -minX, dy: -minY)
    }

    func rotatedRoom(from originalRoom: RoomSettings) -> RoomSettings {
        let points = originalRoom.effectivePolygonPoints
        let cosA = cos(-angle)
        let sinA = sin(-angle)

        var rotatedPoints: [RoomPoint] = []
        for p in points {
            let rx = p.x * cosA - p.y * sinA
            let ry = p.x * sinA + p.y * cosA
            rotatedPoints.append(RoomPoint(x: rx + offset.dx, y: ry + offset.dy))
        }

        // Calculate bounds of rotated points
        let maxX = rotatedPoints.map { $0.x }.max() ?? 0
        let maxY = rotatedPoints.map { $0.y }.max() ?? 0

        // Return new room settings
        // Always return as polygon because even if original was rectangular, rotated is not axis-aligned rect unless 90 deg
        return RoomSettings(
            lengthMm: maxX, // width/height of bounding box
            widthMm: maxY,
            expansionGapMm: originalRoom.expansionGapMm,
            shape: .polygon,
            polygonPoints: rotatedPoints,
            patternType: .straight, // Engine handles straight layout in rotated space
            angleDegrees: 0 // Reset angle
        )
    }

    func transformBack(_ piece: PlacedPiece) -> PlacedPiece {
        // Center of piece in rotated space
        let cx = piece.x + piece.lengthMm / 2
        let cy = piece.y + piece.widthMm / 2

        // Un-shift
        let rx = cx - offset.dx
        let ry = cy - offset.dy

        // Rotate back by +angle
        let cosA = cos(angle)
        let sinA = sin(angle)

        let ox = rx * cosA - ry * sinA
        let oy = rx * sinA + ry * cosA

        // New top-left
        let finalX = ox - piece.lengthMm / 2
        let finalY = oy - piece.widthMm / 2

        var newPiece = piece
        newPiece.x = finalX
        newPiece.y = finalY
        // Add rotation
        // Original rotation (e.g. 0 for laminate, 0/90 for tiles) + layout angle
        newPiece.rotation = piece.rotation + (angle * 180.0 / .pi)

        return newPiece
    }
}
