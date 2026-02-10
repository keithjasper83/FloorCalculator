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

// MARK: - Room Shape

enum RoomShape: String, Codable, CaseIterable {
    case rectangular = "Rectangular"
    case polygon = "Custom Polygon"
}

// MARK: - Installation Pattern

enum InstallationPattern: String, Codable, CaseIterable {
    case straight = "Straight"
    case diagonal = "Diagonal"
}

// MARK: - Room Point

struct RoomPoint: Codable, Equatable, Identifiable {
    var id = UUID()
    var x: Double // mm from origin
    var y: Double // mm from origin
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Room Settings

struct RoomSettings: Codable, Equatable {
    var shape: RoomShape
    
    // Rectangular mode properties
    var lengthMm: Double
    var widthMm: Double
    var expansionGapMm: Double
    
    // Pattern mode properties
    var patternType: InstallationPattern = .straight
    var angleDegrees: Double = 0.0

    // Polygon mode properties
    var polygonPoints: [RoomPoint]
    
    // Computed bounding box (works for both modes)
    var boundingLengthMm: Double {
        if shape == .rectangular {
            return lengthMm
        } else {
            guard !polygonPoints.isEmpty else { return 0 }
            let maxX = polygonPoints.map { $0.x }.max() ?? 0
            let minX = polygonPoints.map { $0.x }.min() ?? 0
            return maxX - minX
        }
    }
    
    var boundingWidthMm: Double {
        if shape == .rectangular {
            return widthMm
        } else {
            guard !polygonPoints.isEmpty else { return 0 }
            let maxY = polygonPoints.map { $0.y }.max() ?? 0
            let minY = polygonPoints.map { $0.y }.min() ?? 0
            return maxY - minY
        }
    }
    
    var usableLengthMm: Double {
        max(0, boundingLengthMm - 2 * expansionGapMm)
    }
    
    var usableWidthMm: Double {
        max(0, boundingWidthMm - 2 * expansionGapMm)
    }
    
    var grossAreaM2: Double {
        if shape == .rectangular {
            return (lengthMm * widthMm) / 1_000_000
        } else {
            return calculatePolygonArea() / 1_000_000
        }
    }
    
    var usableAreaM2: Double {
        if shape == .rectangular {
            return (usableLengthMm * usableWidthMm) / 1_000_000
        } else {
            // For polygon, approximate by reducing by expansion gap
            return max(0, grossAreaM2 - (calculatePerimeter() * expansionGapMm / 1_000_000))
        }
    }
    
    // Initialize with rectangular shape (default)
    init(lengthMm: Double = 5000, widthMm: Double = 4000, expansionGapMm: Double = 10, shape: RoomShape = .rectangular, polygonPoints: [RoomPoint] = [], patternType: InstallationPattern = .straight, angleDegrees: Double = 0.0) {
        self.shape = shape
        self.lengthMm = lengthMm
        self.widthMm = widthMm
        self.expansionGapMm = expansionGapMm
        self.polygonPoints = polygonPoints
        self.patternType = patternType
        self.angleDegrees = angleDegrees
    }
    
    // Calculate polygon area using shoelace formula
    private func calculatePolygonArea() -> Double {
        guard polygonPoints.count >= 3 else { return 0 }
        
        var area: Double = 0
        let n = polygonPoints.count
        
        for i in 0..<n {
            let j = (i + 1) % n
            area += polygonPoints[i].x * polygonPoints[j].y
            area -= polygonPoints[j].x * polygonPoints[i].y
        }
        
        return abs(area / 2.0)
    }
    
    // Calculate polygon perimeter
    private func calculatePerimeter() -> Double {
        guard polygonPoints.count >= 2 else { return 0 }
        
        var perimeter: Double = 0
        let n = polygonPoints.count
        
        for i in 0..<n {
            let j = (i + 1) % n
            let dx = polygonPoints[j].x - polygonPoints[i].x
            let dy = polygonPoints[j].y - polygonPoints[i].y
            perimeter += sqrt(dx * dx + dy * dy)
        }
        
        return perimeter
    }
    
    // Get polygon points (converting rectangle to points if needed)
    var effectivePolygonPoints: [RoomPoint] {
        if shape == .rectangular {
            return [
                RoomPoint(x: 0, y: 0),
                RoomPoint(x: lengthMm, y: 0),
                RoomPoint(x: lengthMm, y: widthMm),
                RoomPoint(x: 0, y: widthMm)
            ]
        } else {
            return polygonPoints
        }
    }

    // Check if a point is inside the room (for layout engines)
    func contains(x: Double, y: Double) -> Bool {
        if shape == .rectangular {
            return x >= 0 && x <= lengthMm && y >= 0 && y <= widthMm
        } else {
            return pointInPolygon(x: x, y: y)
        }
    }
    
    // Ray casting algorithm for point-in-polygon test
    private func pointInPolygon(x: Double, y: Double) -> Bool {
        guard polygonPoints.count >= 3 else { return false }
        
        var inside = false
        let n = polygonPoints.count
        
        var j = n - 1
        for i in 0..<n {
            let xi = polygonPoints[i].x
            let yi = polygonPoints[i].y
            let xj = polygonPoints[j].x
            let yj = polygonPoints[j].y
            
            if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }
        
        return inside
    }
}

// MARK: - Stock Item

struct StockItem: Codable, Equatable, Identifiable {
    var id = UUID()
    var lengthMm: Double
    var widthMm: Double
    var quantity: Int
    var pricePerUnit: Double?
    
    var areaM2: Double {
        (lengthMm * widthMm * Double(quantity)) / 1_000_000
    }

    var totalValue: Double {
        guard let price = pricePerUnit else { return 0 }
        return price * Double(quantity)
    }
}

// MARK: - Laminate Settings

struct LaminateSettings: Codable, Equatable {
    var minStaggerMm: Double
    var minOffcutLengthMm: Double
    var plankDirection: PlankDirection
    var defaultPlankLengthMm: Double
    var defaultPlankWidthMm: Double
    var defaultPricePerPlank: Double?
    
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
    var defaultPricePerTile: Double?
    
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
    var estimatedCost: Double?
    
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
    
    var totalCost: Double

    var isComplete: Bool {
        neededAreaM2 <= 0.01 // tolerance
    }
}

// MARK: - Project

struct Project: Codable, Equatable {
    var id = UUID()
    var name: String
    var currency: String // e.g., "USD", "EUR"
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
        currency: String = "USD",
        materialType: MaterialType = .laminate,
        roomSettings: RoomSettings = RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
        stockItems: [StockItem] = [],
        wasteFactor: Double = 7.0
    ) {
        self.id = UUID()
        self.name = name
        self.currency = currency
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
                defaultPlankWidthMm: 300,
                defaultPricePerPlank: nil
            )
        } else {
            self.tileSettings = TileSettings(
                tileSizeMm: 500,
                pattern: .straight,
                orientation: .monolithic,
                reuseEdgeOffcuts: false,
                tilesPerBox: nil,
                defaultPricePerTile: nil
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
