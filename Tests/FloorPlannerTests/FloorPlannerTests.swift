//
//  FloorPlannerTests.swift
//  FloorPlanner
//
//  Unit tests for layout engines
//

import XCTest
@testable import FloorPlannerCore

final class FloorPlannerTests: XCTestCase {
    
    // MARK: - Model Tests
    
    func testRoomSettingsCalculations() {
        let room = RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10)
        
        XCTAssertEqual(room.usableLengthMm, 4980, accuracy: 0.01)
        XCTAssertEqual(room.usableWidthMm, 3980, accuracy: 0.01)
        XCTAssertEqual(room.grossAreaM2, 20.0, accuracy: 0.01)
        XCTAssertEqual(room.usableAreaM2, 19.8204, accuracy: 0.01)
    }
    
    func testStockItemArea() {
        let item = StockItem(lengthMm: 2000, widthMm: 300, quantity: 10)
        XCTAssertEqual(item.areaM2, 6.0, accuracy: 0.01)
    }
    
    // MARK: - Laminate Engine Tests
    
    func testLaminateEngineWithStock() {
        var project = Project.sampleLaminateProject()
        let engine = LaminateEngine()
        
        let result = engine.generateLayout(project: project, useStock: true)
        
        // Should have placed some pieces
        XCTAssertGreaterThan(result.placedPieces.count, 0)
        
        // Should have some installed area
        XCTAssertGreaterThan(result.installedAreaM2, 0)
        
        // Check that installed + needed + waste + surplus approximately equals stock or room
        let totalAccountedArea = result.installedAreaM2 + result.neededAreaM2 + result.wasteAreaM2 + result.surplusAreaM2
        let stockArea = LayoutUtilities.calculateStockArea(stockItems: project.stockItems)
        XCTAssertEqual(totalAccountedArea, stockArea, accuracy: 1.0)
    }
    
    func testLaminateEngineWithoutStock() {
        var project = Project(
            name: "Test No Stock",
            materialType: .laminate,
            roomSettings: RoomSettings(lengthMm: 3000, widthMm: 2000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 7.0
        )
        
        let engine = LaminateEngine()
        let result = engine.generateLayout(project: project, useStock: false)
        
        // All pieces should be "needed"
        XCTAssertGreaterThan(result.placedPieces.count, 0)
        XCTAssertEqual(result.installedAreaM2, 0, accuracy: 0.01)
        XCTAssertGreaterThan(result.neededAreaM2, 0)
        
        // Should have purchase suggestions
        XCTAssertGreaterThan(result.purchaseSuggestions.count, 0)
    }
    
    // MARK: - Tile Engine Tests
    
    func testTileEngineWithStock() {
        var project = Project(
            name: "Test Tile",
            materialType: .carpetTile,
            roomSettings: RoomSettings(lengthMm: 3000, widthMm: 2000, expansionGapMm: 10),
            stockItems: [
                StockItem(lengthMm: 500, widthMm: 500, quantity: 50)
            ],
            wasteFactor: 10.0
        )
        
        let engine = TileEngine()
        let result = engine.generateLayout(project: project, useStock: true)
        
        // Should have placed some tiles
        XCTAssertGreaterThan(result.placedPieces.count, 0)
        
        // Should have some installed area
        XCTAssertGreaterThan(result.installedAreaM2, 0)
    }
    
    func testTileEngineWithoutStock() {
        var project = Project.sampleTileProject()
        
        let engine = TileEngine()
        let result = engine.generateLayout(project: project, useStock: false)
        
        // All pieces should be "needed"
        XCTAssertGreaterThan(result.placedPieces.count, 0)
        XCTAssertEqual(result.installedAreaM2, 0, accuracy: 0.01)
        XCTAssertGreaterThan(result.neededAreaM2, 0)
        
        // Should have purchase suggestions
        XCTAssertGreaterThan(result.purchaseSuggestions.count, 0)
    }
    
    // MARK: - Layout Utilities Tests
    
    func testCalculateStockArea() {
        let items = [
            StockItem(lengthMm: 2000, widthMm: 300, quantity: 10),
            StockItem(lengthMm: 1000, widthMm: 200, quantity: 5)
        ]
        
        let area = LayoutUtilities.calculateStockArea(stockItems: items)
        XCTAssertEqual(area, 7.0, accuracy: 0.01) // (2000*300*10 + 1000*200*5) / 1_000_000
    }
    
    func testCalculateInstalledArea() {
        let pieces = [
            PlacedPiece(x: 0, y: 0, lengthMm: 1000, widthMm: 200, label: "1", source: .stock, status: .installed, rotation: 0),
            PlacedPiece(x: 1000, y: 0, lengthMm: 1000, widthMm: 200, label: "2", source: .stock, status: .installed, rotation: 0),
            PlacedPiece(x: 2000, y: 0, lengthMm: 1000, widthMm: 200, label: "3", source: .needed, status: .needed, rotation: 0)
        ]
        
        let area = LayoutUtilities.calculateInstalledArea(pieces: pieces)
        XCTAssertEqual(area, 0.4, accuracy: 0.01) // 2 pieces * 1000*200 / 1_000_000
    }
    
    // MARK: - Persistence Tests
    
    func testProjectCoding() throws {
        let project = Project.sampleLaminateProject()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Project.self, from: data)
        
        XCTAssertEqual(project.name, decoded.name)
        XCTAssertEqual(project.materialType, decoded.materialType)
        XCTAssertEqual(project.roomSettings, decoded.roomSettings)
        XCTAssertEqual(project.stockItems.count, decoded.stockItems.count)
    }
    
    func testCSVExport() {
        let result = LayoutResult(
            placedPieces: [
                PlacedPiece(x: 0, y: 0, lengthMm: 1000, widthMm: 200, label: "S1", source: .stock, status: .installed, rotation: 0)
            ],
            cutRecords: [],
            remainingPieces: [],
            purchaseSuggestions: [],
            installedAreaM2: 0.2,
            neededAreaM2: 0,
            wasteAreaM2: 0,
            surplusAreaM2: 0
        )
        
        let csv = PersistenceManager.shared.exportPlacementCSV(result: result)
        
        XCTAssertTrue(csv.contains("Label,X(mm),Y(mm)"))
        XCTAssertTrue(csv.contains("S1"))
        XCTAssertTrue(csv.contains("1000"))
    }
}
