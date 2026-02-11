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
            surplusAreaM2: 0,
            totalCost: 0
        )
        
        let csv = PersistenceManager.shared.exportPlacementCSV(result: result)
        
        XCTAssertTrue(csv.contains("Label,X(mm),Y(mm)"))
        XCTAssertTrue(csv.contains("S1"))
        XCTAssertTrue(csv.contains("1000"))
    }
    
    // MARK: - Polygon Room Tests
    
    func testPolygonRoomArea() {
        // Test square polygon
        let squarePoints = [
            RoomPoint(x: 0, y: 0),
            RoomPoint(x: 1000, y: 0),
            RoomPoint(x: 1000, y: 1000),
            RoomPoint(x: 0, y: 1000)
        ]
        
        let squareRoom = RoomSettings(
            lengthMm: 1000,
            widthMm: 1000,
            expansionGapMm: 10,
            shape: .polygon,
            polygonPoints: squarePoints
        )
        
        // Area should be 1,000,000 mm² = 1.0 m²
        XCTAssertEqual(squareRoom.grossAreaM2, 1.0, accuracy: 0.01)
    }
    
    func testPolygonRoomLShapedArea() {
        // Test L-shaped polygon (6m x 4m minus 2m x 2m cut-out)
        let lShapePoints = [
            RoomPoint(x: 0, y: 0),
            RoomPoint(x: 6000, y: 0),
            RoomPoint(x: 6000, y: 4000),
            RoomPoint(x: 2000, y: 4000),
            RoomPoint(x: 2000, y: 2000),
            RoomPoint(x: 0, y: 2000)
        ]
        
        let lShapeRoom = RoomSettings(
            lengthMm: 6000,
            widthMm: 4000,
            expansionGapMm: 10,
            shape: .polygon,
            polygonPoints: lShapePoints
        )
        
        // Expected area: (6m × 4m) - (4m × 2m) = 24 - 8 = 16 m²
        XCTAssertEqual(lShapeRoom.grossAreaM2, 16.0, accuracy: 0.1)
    }
    
    func testPolygonRoomPointInside() {
        // Test square polygon
        let squarePoints = [
            RoomPoint(x: 0, y: 0),
            RoomPoint(x: 1000, y: 0),
            RoomPoint(x: 1000, y: 1000),
            RoomPoint(x: 0, y: 1000)
        ]
        
        let squareRoom = RoomSettings(
            lengthMm: 1000,
            widthMm: 1000,
            expansionGapMm: 10,
            shape: .polygon,
            polygonPoints: squarePoints
        )
        
        // Point inside
        XCTAssertTrue(squareRoom.contains(x: 500, y: 500))
        
        // Point outside
        XCTAssertFalse(squareRoom.contains(x: 1500, y: 500))
        XCTAssertFalse(squareRoom.contains(x: 500, y: 1500))
        
        // Point on edge (boundary points treated as inside per ray casting convention)
        XCTAssertTrue(squareRoom.contains(x: 0, y: 500), "Boundary points should be considered inside")
        XCTAssertTrue(squareRoom.contains(x: 1000, y: 500), "Boundary points should be considered inside")
    }
    
    func testPolygonRoomBoundingBox() {
        let irregularPoints = [
            RoomPoint(x: 100, y: 200),
            RoomPoint(x: 500, y: 100),
            RoomPoint(x: 800, y: 400),
            RoomPoint(x: 300, y: 600)
        ]
        
        let irregularRoom = RoomSettings(
            lengthMm: 800,
            widthMm: 600,
            expansionGapMm: 10,
            shape: .polygon,
            polygonPoints: irregularPoints
        )
        
        // Bounding box should be 700 x 500
        XCTAssertEqual(irregularRoom.boundingLengthMm, 700, accuracy: 0.1)
        XCTAssertEqual(irregularRoom.boundingWidthMm, 500, accuracy: 0.1)
    }
    
    func testRectangularRoomBackwardCompatibility() {
        // Ensure rectangular rooms still work as before
        let rectRoom = RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10)
        
        XCTAssertEqual(rectRoom.shape, .rectangular)
        XCTAssertEqual(rectRoom.grossAreaM2, 20.0, accuracy: 0.01)
        XCTAssertEqual(rectRoom.usableAreaM2, 19.8204, accuracy: 0.01)
        XCTAssertTrue(rectRoom.contains(x: 2500, y: 2000))
        XCTAssertFalse(rectRoom.contains(x: 6000, y: 2000))
    }
    
    // MARK: - CalculatedEngine Tests
    
    func testCalculatedEngineWithPaint() {
        // Test paint calculation (coverage-based)
        let paintMaterial = Material.paint
        let engine = CalculatedEngine(material: paintMaterial, thicknessMm: 0)
        
        // 10m x 5m room = 50 m²
        let project = Project(
            name: "Test Paint",
            materialType: .paint,
            roomSettings: RoomSettings(lengthMm: 10000, widthMm: 5000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 0.0
        )
        
        let result = engine.generateLayout(project: project, useStock: false)
        
        // Paint has 10 m² per liter coverage, so 50 m² / 10 = 5 liters
        XCTAssertEqual(result.purchaseSuggestions.count, 1)
        XCTAssertEqual(result.purchaseSuggestions[0].quantityValue, 5.0, accuracy: 0.01)
        XCTAssertEqual(result.purchaseSuggestions[0].unitName, "Liter")
        
        // Should have full coverage
        XCTAssertEqual(result.installedAreaM2, 49.9002, accuracy: 0.01) // usable area
        XCTAssertEqual(result.neededAreaM2, 0, accuracy: 0.01)
        
        // Check cost calculation: 49.9002 m² / 10 m²/liter * 20.0 per liter = 99.8004
        XCTAssertEqual(result.totalCost, 99.8004, accuracy: 0.1)
    }
    
    func testCalculatedEngineWithConcrete() {
        // Test concrete calculation (volume-based)
        let concreteMaterial = Material.concrete
        let thickness = 100.0 // 100mm = 0.1m
        let engine = CalculatedEngine(material: concreteMaterial, thicknessMm: thickness)
        
        // 10m x 5m room = 50 m²
        let project = Project(
            name: "Test Concrete",
            materialType: .concrete,
            roomSettings: RoomSettings(lengthMm: 10000, widthMm: 5000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 0.0
        )
        
        let result = engine.generateLayout(project: project, useStock: false)
        
        // Volume = 49.9002 m² * 0.1 m = 4.99002 m³
        XCTAssertEqual(result.purchaseSuggestions.count, 1)
        XCTAssertEqual(result.purchaseSuggestions[0].quantityValue, 4.99002, accuracy: 0.01)
        XCTAssertEqual(result.purchaseSuggestions[0].unitName, "m³")
        
        // Should have full coverage
        XCTAssertEqual(result.installedAreaM2, 49.9002, accuracy: 0.01)
        XCTAssertEqual(result.neededAreaM2, 0, accuracy: 0.01)
        
        // Check cost calculation: 49.9002 m² * 0.1 m * 150.0 per m³ = 748.503
        XCTAssertEqual(result.totalCost, 748.503, accuracy: 0.1)
    }
    
    func testCalculatedEngineWithZeroThickness() {
        // Test with zero thickness (should fall back to default or handle gracefully)
        let concreteMaterial = Material.concrete
        let engine = CalculatedEngine(material: concreteMaterial, thicknessMm: 0)
        
        let project = Project(
            name: "Test Zero Thickness",
            materialType: .concrete,
            roomSettings: RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 0.0
        )
        
        let result = engine.generateLayout(project: project, useStock: false)
        
        // With zero thickness, volume should be 0
        XCTAssertEqual(result.purchaseSuggestions[0].quantityValue, 0.0, accuracy: 0.01)
    }
    
    func testCalculatedEnginePrecision() {
        // Test that fractional quantities are preserved
        let paintMaterial = Material.paint
        let engine = CalculatedEngine(material: paintMaterial, thicknessMm: 0)
        
        // 15.5 m² area
        let project = Project(
            name: "Test Precision",
            materialType: .paint,
            roomSettings: RoomSettings(lengthMm: 5000, widthMm: 3100, expansionGapMm: 0),
            stockItems: [],
            wasteFactor: 0.0
        )
        
        let result = engine.generateLayout(project: project, useStock: false)
        
        // Paint has 10 m² per liter coverage, so 15.5 m² / 10 = 1.55 liters
        XCTAssertEqual(result.purchaseSuggestions[0].quantityValue, 1.55, accuracy: 0.01)
        // quantityNeeded should round up
        XCTAssertEqual(result.purchaseSuggestions[0].quantityNeeded, 2)
    }
}
