//
//  Models.swift
//  FloorPlanner
//
//  Core data models for the Floor Planner app
//

import Foundation

// MARK: - Material Type

enum MaterialType: String, Codable, CaseIterable {
    case laminate = "Laminate Planks"
    case carpetTile = "Carpet Tiles"
}

// MARK: - Room Settings

struct RoomSettings: Codable, Equatable {
    var lengthMm: Double
    var widthMm: Double
    var expansionGapMm: Double
    
    var usableLengthMm: Double {
        lengthMm - 2 * expansionGapMm
    }
    
    var usableWidthMm: Double {
        widthMm - 2 * expansionGapMm
    }
    
    var grossAreaM2: Double {
        (lengthMm * widthMm) / 1_000_000
    }
    
    var usableAreaM2: Double {
        (usableLengthMm * usableWidthMm) / 1_000_000
    }
}

// MARK: - Stock Item

struct StockItem: Codable, Equatable, Identifiable {
    var id = UUID()
    var lengthMm: Double
    var widthMm: Double
    var quantity: Int
    
    var areaM2: Double {
        (lengthMm * widthMm * Double(quantity)) / 1_000_000
    }
}

// MARK: - Laminate Settings

struct LaminateSettings: Codable, Equatable {
    var minStaggerMm: Double
    var minOffcutLengthMm: Double
    var plankDirection: PlankDirection
    var defaultPlankLengthMm: Double
    var defaultPlankWidthMm: Double
    
    enum PlankDirection: String, Codable, CaseIterable {
        case alongLength = "Along Length"
        case alongWidth = "Along Width"
    }
}

// MARK: - Tile Settings

struct TileSettings: Codable, Equatable {
    var tileSizeMm: Double
    var pattern: TilePattern
    var orientation: TileOrientation
    var reuseEdgeOffcuts: Bool
    var tilesPerBox: Int?
    
    enum TilePattern: String, Codable, CaseIterable {
        case straight = "Straight Grid"
        case brick = "Brick/Offset"
    }
    
    enum TileOrientation: String, Codable, CaseIterable {
        case monolithic = "Monolithic"
        case quarterTurn = "Quarter-Turn"
    }
}

// MARK: - Placed Piece

struct PlacedPiece: Codable, Equatable, Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
    var lengthMm: Double
    var widthMm: Double
    var label: String
    var source: PieceSource
    var status: PieceStatus
    var rotation: Double // degrees, for quarter-turn tiles
    
    enum PieceSource: String, Codable {
        case stock = "Stock"
        case offcut = "Offcut"
        case needed = "Needed"
    }
    
    enum PieceStatus: String, Codable {
        case installed = "Installed"
        case needed = "Needed"
    }
    
    var areaM2: Double {
        (lengthMm * widthMm) / 1_000_000
    }
}

// MARK: - Cut Record

struct CutRecord: Codable, Equatable, Identifiable {
    var id = UUID()
    var materialType: MaterialType
    
    // Laminate-specific
    var row: Int?
    var cutType: LaminateCutType?
    var fromLengthMm: Double?
    var cutToMm: Double?
    var offcutLengthMm: Double?
    var widthMm: Double?
    
    // Tile-specific
    var edgeCutCount: Int?
    var cutDimensionsMm: String?
    
    enum LaminateCutType: String, Codable {
        case startCut = "Start Cut"
        case endCut = "End Cut"
    }
}

// MARK: - Remaining Piece

struct RemainingPiece: Codable, Equatable, Identifiable {
    var id = UUID()
    var lengthMm: Double
    var widthMm: Double
    var source: PlacedPiece.PieceSource
    
    var areaM2: Double {
        (lengthMm * widthMm) / 1_000_000
    }
}

// MARK: - Purchase Suggestion

struct PurchaseSuggestion: Codable, Equatable, Identifiable {
    var id = UUID()
    var unitLengthMm: Double
    var unitWidthMm: Double
    var quantityNeeded: Int
    var packsNeeded: Int?
    
    var totalAreaM2: Double {
        (unitLengthMm * unitWidthMm * Double(quantityNeeded)) / 1_000_000
    }
}

// MARK: - Layout Result

struct LayoutResult: Codable, Equatable {
    var placedPieces: [PlacedPiece]
    var cutRecords: [CutRecord]
    var remainingPieces: [RemainingPiece]
    var purchaseSuggestions: [PurchaseSuggestion]
    
    var installedAreaM2: Double
    var neededAreaM2: Double
    var wasteAreaM2: Double
    var surplusAreaM2: Double
    
    var isComplete: Bool {
        neededAreaM2 <= 0.01 // tolerance
    }
}

// MARK: - Project

struct Project: Codable, Equatable {
    var id = UUID()
    var name: String
    var materialType: MaterialType
    var roomSettings: RoomSettings
    var stockItems: [StockItem]
    var wasteFactor: Double // percentage, e.g., 7.0 for 7%
    
    var laminateSettings: LaminateSettings?
    var tileSettings: TileSettings?
    
    var createdAt: Date
    var modifiedAt: Date
    
    init(
        name: String = "New Project",
        materialType: MaterialType = .laminate,
        roomSettings: RoomSettings = RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
        stockItems: [StockItem] = [],
        wasteFactor: Double = 7.0
    ) {
        self.id = UUID()
        self.name = name
        self.materialType = materialType
        self.roomSettings = roomSettings
        self.stockItems = stockItems
        self.wasteFactor = wasteFactor
        
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
        
        // Initialize material-specific settings
        if materialType == .laminate {
            self.laminateSettings = LaminateSettings(
                minStaggerMm: 200,
                minOffcutLengthMm: 150,
                plankDirection: .alongLength,
                defaultPlankLengthMm: 1000,
                defaultPlankWidthMm: 300
            )
        } else {
            self.tileSettings = TileSettings(
                tileSizeMm: 500,
                pattern: .straight,
                orientation: .monolithic,
                reuseEdgeOffcuts: false,
                tilesPerBox: nil
            )
        }
    }
    
    static func sampleLaminateProject() -> Project {
        var project = Project(
            name: "Sample Laminate Project",
            materialType: .laminate,
            roomSettings: RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
            stockItems: [
                StockItem(lengthMm: 2405, widthMm: 300, quantity: 13),
                StockItem(lengthMm: 2159, widthMm: 300, quantity: 2),
                StockItem(lengthMm: 1607, widthMm: 200, quantity: 6),
                StockItem(lengthMm: 1202, widthMm: 300, quantity: 6)
            ],
            wasteFactor: 7.0
        )
        return project
    }
    
    static func sampleTileProject() -> Project {
        var project = Project(
            name: "Sample Tile Project",
            materialType: .carpetTile,
            roomSettings: RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 10.0
        )
        return project
    }
}
