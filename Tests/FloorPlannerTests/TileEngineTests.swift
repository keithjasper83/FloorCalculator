//
//  TileEngineTests.swift
//  FloorPlannerTests
//
//  Tests for TileEngine layout logic
//

import XCTest
@testable import FloorPlannerCore

final class TileEngineTests: XCTestCase {

    func testTileEngineBrickPattern() {
        let tileSize = 500.0
        let roomLength = 2000.0
        let roomWidth = 1000.0 // 2 rows

        var project = Project(
            name: "Brick Pattern Test",
            materialType: .carpetTile,
            roomSettings: RoomSettings(lengthMm: roomLength, widthMm: roomWidth, expansionGapMm: 0),
            stockItems: [],
            wasteFactor: 0.0
        )

        // Configure brick pattern
        let settings = TileSettings(
            tileSizeMm: tileSize,
            pattern: .brick,
            orientation: .monolithic,
            reuseEdgeOffcuts: false
        )
        project.tileSettings = settings

        let engine = TileEngine()
        let result = engine.generateLayout(project: project, useStock: false)

        // Verification:
        // Row 0 should have X coordinates at 0, 500, 1000, 1500
        // Row 1 should be offset by 250 (tileSize / 2)
        // Row 1 X coordinates should be at -250 (clipped to 0), 250, 750, 1250, 1750

        let placedPieces = result.placedPieces

        // Group by row (Y coordinate)
        let row0 = placedPieces.filter { abs($0.y - 0) < 0.1 }
        let row1 = placedPieces.filter { abs($0.y - 500) < 0.1 }

        XCTAssertGreaterThan(row0.count, 0)
        XCTAssertGreaterThan(row1.count, 0)

        // Row 0 tiles should start at 0, 500, 1000, 1500
        let row0X = row0.map { $0.x }.sorted()
        XCTAssertEqual(row0X.count, 4)
        XCTAssertEqual(row0X[0], 0, accuracy: 0.1)
        XCTAssertEqual(row0X[1], 500, accuracy: 0.1)
        XCTAssertEqual(row0X[2], 1000, accuracy: 0.1)
        XCTAssertEqual(row0X[3], 1500, accuracy: 0.1)

        // Row 1 tiles should start at 0 (was -250, clipped), 250, 750, 1250, 1750
        let row1X = row1.map { $0.x }.sorted()
        XCTAssertEqual(row1X.count, 5)
        XCTAssertEqual(row1X[0], 0, accuracy: 0.1)
        XCTAssertEqual(row1X[1], 250, accuracy: 0.1)
        XCTAssertEqual(row1X[2], 750, accuracy: 0.1)
        XCTAssertEqual(row1X[3], 1250, accuracy: 0.1)
        XCTAssertEqual(row1X[4], 1750, accuracy: 0.1)

        // Check piece widths for row 1
        let row1Sorted = row1.sorted(by: { $0.x < $1.x })
        let row1Widths = row1Sorted.map { $0.lengthMm }
        XCTAssertEqual(row1Widths[0], 250, accuracy: 0.1) // First piece is clipped
        XCTAssertEqual(row1Widths[1], 500, accuracy: 0.1)
        XCTAssertEqual(row1Widths[2], 500, accuracy: 0.1)
        XCTAssertEqual(row1Widths[3], 500, accuracy: 0.1)
        XCTAssertEqual(row1Widths[4], 250, accuracy: 0.1) // Last piece is clipped (2000 - 1750 = 250)
    }

    func testTileEngineQuarterTurn() {
        let tileSize = 500.0
        let roomLength = 1000.0
        let roomWidth = 1000.0

        var project = Project(
            name: "Quarter Turn Test",
            materialType: .carpetTile,
            roomSettings: RoomSettings(lengthMm: roomLength, widthMm: roomWidth, expansionGapMm: 0),
            stockItems: [],
            wasteFactor: 0.0
        )

        let settings = TileSettings(
            tileSizeMm: tileSize,
            pattern: .straight,
            orientation: .quarterTurn,
            reuseEdgeOffcuts: false
        )
        project.tileSettings = settings

        let engine = TileEngine()
        let result = engine.generateLayout(project: project, useStock: false)

        let placedPieces = result.placedPieces
        XCTAssertEqual(placedPieces.count, 4)

        // Group by row and col
        // (row, col) coordinates:
        // (0, 0) -> rotation 0
        // (0, 1) -> rotation 90
        // (1, 0) -> rotation 90
        // (1, 1) -> rotation 0
        // Formula in code: rotation = ((row + col) % 2 == 0) ? 0.0 : 90.0

        // Re-simulate the engine loop logic to find the 'col' index
        for piece in placedPieces {
            // Find which grid position this piece corresponds to
            // For straight pattern, startX is always col * tileSize
            let col = Int(round(piece.x / tileSize))
            let row = Int(round(piece.y / tileSize))

            let expectedRotation = ((row + col) % 2 == 0) ? 0.0 : 90.0
            XCTAssertEqual(piece.rotation, expectedRotation, "Piece at (\(col), \(row)) has wrong rotation")
        }
    }
}
