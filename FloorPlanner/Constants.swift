//
//  Constants.swift
//  FloorPlanner
//
//  Shared constants and magic numbers for the application
//

import Foundation

struct Constants {
    // MARK: - Geometry & Layout

    /// Tolerance for floating point comparisons and geometry checks (mm)
    static let geometryToleranceMm: Double = 0.1

    /// Tolerance for area comparisons (m²)
    static let areaToleranceM2: Double = 0.01

    /// Tolerance for angular comparisons (degrees)
    static let angleToleranceDegrees: Double = 0.1

    /// Slightly larger tolerance for snapping/alignment (mm)
    static let snapToleranceMm: Double = 1.0

    // MARK: - Defaults

    struct Defaults {
        static let roomLengthMm: Double = 5000
        static let roomWidthMm: Double = 4000
        static let expansionGapMm: Double = 10

        static let laminateStaggerMm: Double = 200
        static let laminateOffcutMm: Double = 150
        static let laminatePlankLengthMm: Double = 1000
        static let laminatePlankWidthMm: Double = 300

        static let tileSizeMm: Double = 500

        static let wasteFactorPercentage: Double = 7.0
    }

    // MARK: - Strings

    struct MaterialNames {
        static let laminate = "Laminate Planks"
        static let carpetTile = "Carpet Tiles"
        static let vinylPlank = "Vinyl Planks"
        static let engineeredWood = "Engineered Wood"
        static let ceramicTile = "Ceramic Tiles"
        static let concrete = "Concrete"
        static let paint = "Paint"
        static let plasterboard = "Plasterboard"
    }
}
