//
//  Materials.swift
//  FloorPlanner
//
//  Domain model for materials, layers, and surfaces
//

import Foundation

// MARK: - Material Calculation Type

/// Defines how the material quantity is calculated
enum MaterialCalculationType: String, Codable, CaseIterable {
    /// Discrete items (e.g., tiles, planks) counted by piece
    case discrete

    /// Continuous material (e.g., paint, concrete) calculated by volume or area
    case continuous
}

// MARK: - Material Category

/// Broad category for material classification
enum MaterialCategory: String, Codable, CaseIterable {
    case flooring = "Flooring"
    case wallCovering = "Wall Covering"
    case liquid = "Liquid/Applied"
    case structural = "Structural"
}

// MARK: - Material Definition

/// Defines a specific material with its properties
struct Material: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var category: MaterialCategory
    var calculationType: MaterialCalculationType

    // Discrete Properties
    var defaultLengthMm: Double?
    var defaultWidthMm: Double?
    var defaultThicknessMm: Double?

    // Continuous Properties
    var coveragePerUnit: Double? // e.g., m2 per liter/kg
    var unitName: String? // e.g., "Liter", "Kg", "Bag"

    // Cost
    var pricePerUnit: Double?

    init(
        id: UUID = UUID(),
        name: String,
        category: MaterialCategory,
        calculationType: MaterialCalculationType,
        defaultLengthMm: Double? = nil,
        defaultWidthMm: Double? = nil,
        defaultThicknessMm: Double? = nil,
        coveragePerUnit: Double? = nil,
        unitName: String? = nil,
        pricePerUnit: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.calculationType = calculationType
        self.defaultLengthMm = defaultLengthMm
        self.defaultWidthMm = defaultWidthMm
        self.defaultThicknessMm = defaultThicknessMm
        self.coveragePerUnit = coveragePerUnit
        self.unitName = unitName
        self.pricePerUnit = pricePerUnit
    }

    // MARK: - Preset Materials

    static let laminate = Material(
        name: Constants.MaterialNames.laminate,
        category: .flooring,
        calculationType: .discrete,
        defaultLengthMm: Constants.Defaults.laminatePlankLengthMm,
        defaultWidthMm: Constants.Defaults.laminatePlankWidthMm,
        defaultThicknessMm: 8.0
    )

    static let carpetTile = Material(
        name: Constants.MaterialNames.carpetTile,
        category: .flooring,
        calculationType: .discrete,
        defaultLengthMm: Constants.Defaults.tileSizeMm,
        defaultWidthMm: Constants.Defaults.tileSizeMm,
        defaultThicknessMm: 5.0
    )

    static let vinylPlank = Material(
        name: Constants.MaterialNames.vinylPlank,
        category: .flooring,
        calculationType: .discrete,
        defaultLengthMm: Constants.Defaults.laminatePlankLengthMm,
        defaultWidthMm: Constants.Defaults.laminatePlankWidthMm,
        defaultThicknessMm: 5.0
    )

    static let engineeredWood = Material(
        name: Constants.MaterialNames.engineeredWood,
        category: .flooring,
        calculationType: .discrete,
        defaultLengthMm: Constants.Defaults.laminatePlankLengthMm,
        defaultWidthMm: Constants.Defaults.laminatePlankWidthMm,
        defaultThicknessMm: 15.0
    )

    static let ceramicTile = Material(
        name: Constants.MaterialNames.ceramicTile,
        category: .flooring,
        calculationType: .discrete,
        defaultLengthMm: Constants.Defaults.tileSizeMm,
        defaultWidthMm: Constants.Defaults.tileSizeMm,
        defaultThicknessMm: 8.0
    )

    static let concrete = Material(
        name: Constants.MaterialNames.concrete,
        category: .structural,
        calculationType: .continuous,
        unitName: "m³",
        pricePerUnit: 150.0 // per m3
    )

    static let paint = Material(
        name: Constants.MaterialNames.paint,
        category: .liquid,
        calculationType: .continuous,
        coveragePerUnit: 10.0, // 10 m2 per liter
        unitName: "Liter",
        pricePerUnit: 20.0
    )

    static let plasterboard = Material(
        name: Constants.MaterialNames.plasterboard,
        category: .wallCovering,
        calculationType: .discrete,
        defaultLengthMm: 2400,
        defaultWidthMm: 1200,
        defaultThicknessMm: 12.5
    )
}

// MARK: - Layer

/// Represents a single layer of material on a surface
struct Layer: Codable, Identifiable, Equatable {
    var id: UUID
    var material: Material
    var thicknessMm: Double
    var isVisible: Bool

    // Material-specific settings overrides
    // (e.g., stagger for laminate, pattern for tile)
    // Stored as JSON data or specific optional structs
    // For simplicity, we can link back to Project settings or embed here.
    // Given the current architecture, we might want to embed specific settings.

    // Laminate specific
    var laminateSettings: LaminateSettings?

    // Tile specific
    var tileSettings: TileSettings?

    init(
        id: UUID = UUID(),
        material: Material,
        thicknessMm: Double? = nil,
        isVisible: Bool = true,
        laminateSettings: LaminateSettings? = nil,
        tileSettings: TileSettings? = nil
    ) {
        self.id = id
        self.material = material
        self.thicknessMm = thicknessMm ?? material.defaultThicknessMm ?? 0.0
        self.isVisible = isVisible
        self.laminateSettings = laminateSettings
        self.tileSettings = tileSettings
    }
}

// MARK: - Surface

/// Represents a physical surface (Floor, Wall, Ceiling)
struct Surface: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var type: SurfaceType
    var layers: [Layer]

    // Geometry is currently handled by RoomSettings, but ideally belongs here
    // For V1 compatibility, we assume this surface applies to the Room geometry

    init(id: UUID = UUID(), name: String, type: SurfaceType, layers: [Layer] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.layers = layers
    }
}

enum SurfaceType: String, Codable {
    case floor = "Floor"
    case wall = "Wall"
    case ceiling = "Ceiling"
}
