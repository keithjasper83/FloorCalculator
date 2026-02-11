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
    case vinylPlank = "Vinyl Planks"
    case engineeredWood = "Engineered Wood"
    case ceramicTile = "Ceramic Tiles"
    case concrete = "Concrete"
    case paint = "Paint"
    case plasterboard = "Plasterboard"

    // Helper to convert to Domain Material
    var toDomainMaterial: Material {
        switch self {
        case .laminate: return .laminate
        case .carpetTile: return .carpetTile
        case .vinylPlank: return .vinylPlank
        case .engineeredWood: return .engineeredWood
        case .ceramicTile: return .ceramicTile
        case .concrete: return .concrete
        case .paint: return .paint
        case .plasterboard: return .plasterboard
        }
    }
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

    // Support for both integer (items) and double (volume)
    var quantityValue: Double

    var quantityNeeded: Int {
        return Int(ceil(quantityValue))
    }

    var packsNeeded: Int?
    var estimatedCost: Double?
    var unitName: String? // Unit name for continuous materials (e.g., "Liter", "m³")
    
    var totalAreaM2: Double {
        (unitLengthMm * unitWidthMm * quantityValue) / 1_000_000
    }

    init(id: UUID = UUID(), unitLengthMm: Double, unitWidthMm: Double, quantityNeeded: Int, packsNeeded: Int? = nil, estimatedCost: Double? = nil, unitName: String? = nil) {
        self.id = id
        self.unitLengthMm = unitLengthMm
        self.unitWidthMm = unitWidthMm
        self.quantityValue = Double(quantityNeeded)
        self.packsNeeded = packsNeeded
        self.estimatedCost = estimatedCost
        self.unitName = unitName
    }

    // New init for Double quantity
    init(id: UUID = UUID(), unitLengthMm: Double, unitWidthMm: Double, quantityValue: Double, packsNeeded: Int? = nil, estimatedCost: Double? = nil, unitName: String? = nil) {
        self.id = id
        self.unitLengthMm = unitLengthMm
        self.unitWidthMm = unitWidthMm
        self.quantityValue = quantityValue
        self.packsNeeded = packsNeeded
        self.estimatedCost = estimatedCost
        self.unitName = unitName
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
        neededAreaM2 <= Constants.areaToleranceM2
    }
}

// MARK: - Project

struct Project: Codable, Equatable {
    var id = UUID()
    var name: String
    var currency: String // e.g., "USD", "EUR"
    var roomSettings: RoomSettings
    var stockItems: [StockItem]
    var wasteFactor: Double // percentage, e.g., 7.0 for 7%
    
    // V2: Multiple Layers
    var layers: [Layer]
    
    var createdAt: Date
    var modifiedAt: Date
    
    // Backward Compatibility Wrappers

    var materialType: MaterialType {
        get {
            // Infer from first layer
            guard let firstLayer = layers.first else { return .laminate }
            // Try to map Material name back to Type
            if let type = MaterialType(rawValue: firstLayer.material.name) {
                return type
            }
            return .laminate
        }
        set {
            // Update first layer
            if layers.isEmpty {
                layers.append(Layer(material: newValue.toDomainMaterial))
            } else {
                var layer = layers[0]
                layer.material = newValue.toDomainMaterial
                // Preserve settings if applicable
                layers[0] = layer
            }
            ensureSettingsExist(for: newValue)
        }
    }

    var laminateSettings: LaminateSettings? {
        get { layers.first?.laminateSettings }
        set {
            if !layers.isEmpty {
                layers[0].laminateSettings = newValue
            }
        }
    }

    var tileSettings: TileSettings? {
        get { layers.first?.tileSettings }
        set {
            if !layers.isEmpty {
                layers[0].tileSettings = newValue
            }
        }
    }

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
        self.roomSettings = roomSettings
        self.stockItems = stockItems
        self.wasteFactor = wasteFactor
        
        let now = Date()
        self.createdAt = now
        self.modifiedAt = now
        
        // Initialize layers with default material
        self.layers = [Layer(material: materialType.toDomainMaterial)]

        ensureSettingsExist(for: materialType)
    }

    private mutating func ensureSettingsExist(for type: MaterialType) {
        let laminateTypes: [MaterialType] = [.laminate, .vinylPlank, .engineeredWood]
        let tileTypes: [MaterialType] = [.carpetTile, .ceramicTile]

        if laminateTypes.contains(type) && layers[0].laminateSettings == nil {
            layers[0].laminateSettings = LaminateSettings(
                minStaggerMm: 200,
                minOffcutLengthMm: 150,
                plankDirection: .alongLength,
                defaultPlankLengthMm: 1000,
                defaultPlankWidthMm: 300,
                defaultPricePerPlank: nil
            )
        } else if tileTypes.contains(type) && layers[0].tileSettings == nil {
            layers[0].tileSettings = TileSettings(
                tileSizeMm: 500,
                pattern: .straight,
                orientation: .monolithic,
                reuseEdgeOffcuts: false,
                tilesPerBox: nil,
                defaultPricePerTile: nil
            )
        }
    }
    
    // Custom CodingKeys to handle migration
    enum CodingKeys: String, CodingKey {
        case id, name, currency, roomSettings, stockItems, wasteFactor, createdAt, modifiedAt
        case layers
        // Legacy keys
        case materialType, laminateSettings, tileSettings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        currency = try container.decode(String.self, forKey: .currency)
        roomSettings = try container.decode(RoomSettings.self, forKey: .roomSettings)
        stockItems = try container.decode([StockItem].self, forKey: .stockItems)
        wasteFactor = try container.decode(Double.self, forKey: .wasteFactor)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)

        // Try to decode layers (V2)
        if let decodedLayers = try? container.decode([Layer].self, forKey: .layers) {
            layers = decodedLayers
        } else {
            // Migration: Decode legacy fields and build layer
            let type = try container.decode(MaterialType.self, forKey: .materialType)
            var layer = Layer(material: type.toDomainMaterial)

            if let lamSettings = try? container.decode(LaminateSettings.self, forKey: .laminateSettings) {
                layer.laminateSettings = lamSettings
            }
            if let tSettings = try? container.decode(TileSettings.self, forKey: .tileSettings) {
                layer.tileSettings = tSettings
            }
            layers = [layer]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(currency, forKey: .currency)
        try container.encode(roomSettings, forKey: .roomSettings)
        try container.encode(stockItems, forKey: .stockItems)
        try container.encode(wasteFactor, forKey: .wasteFactor)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)

        try container.encode(layers, forKey: .layers)

        // Encode legacy fields for backward compatibility (optional, but good for rolling back)
        try container.encode(materialType, forKey: .materialType)
        try container.encode(laminateSettings, forKey: .laminateSettings)
        try container.encode(tileSettings, forKey: .tileSettings)
    }

    static func sampleLaminateProject() -> Project {
        return Project(
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
    }
    
    static func sampleTileProject() -> Project {
        return Project(
            name: "Sample Tile Project",
            materialType: .carpetTile,
            roomSettings: RoomSettings(lengthMm: 5000, widthMm: 4000, expansionGapMm: 10),
            stockItems: [],
            wasteFactor: 10.0
        )
    }
}
