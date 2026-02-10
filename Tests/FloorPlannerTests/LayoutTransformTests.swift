//
//  LayoutTransformTests.swift
//  FloorPlannerTests
//
//  Tests for diagonal layout transformation
//

import XCTest
@testable import FloorPlannerCore

final class LayoutTransformTests: XCTestCase {

    func testRotationCalculations() {
        // Test 45 degree rotation of a 10x10 square
        let original = RoomSettings(lengthMm: 10, widthMm: 10, expansionGapMm: 0)
        let angle = 45.0
        let transform = LayoutTransform(room: original, angleDegrees: angle)

        // Rotated room should have larger bounding box
        // Diagonal of 10x10 is 10*sqrt(2) approx 14.14
        let rotated = transform.rotatedRoom(from: original)

        // For 45 deg, the bounding box width = height = diagonal length
        XCTAssertEqual(rotated.lengthMm, 10 * sqrt(2), accuracy: 0.001)
        XCTAssertEqual(rotated.widthMm, 10 * sqrt(2), accuracy: 0.001)

        // Create a piece that represents a point in the rotated coordinate space
        // Center of rotated room logic check:
        // Original points: (0,0), (10,0), (10,10), (0,10)
        // Rotated -45 around (0,0):
        // p0: (0,0)
        // p1: (7.071, -7.071)
        // p2: (14.142, 0)
        // p3: (7.071, 7.071)
        // minX = 0, maxX = 14.142
        // minY = -7.071, maxY = 7.071
        // Offset: dx = -0 = 0, dy = -(-7.071) = 7.071

        // Center of original room (5, 5).
        // Rotate (5,5) by -45 around (0,0):
        // x' = 5*cos(-45) - 5*sin(-45) = 5*0.707 - 5*(-0.707) = 3.535 + 3.535 = 7.071
        // y' = 5*sin(-45) + 5*cos(-45) = 5*(-0.707) + 5*0.707 = 0
        // Shift by (0, 7.071) -> (7.071, 7.071).

        // So the center of the original room maps to (7.071, 7.071) in the rotated positive space.
        // This is exactly half of (14.142, 14.142). Correct.

        // Now test transformBack
        // Let's create a piece centered at (7.071, 7.071) with size 2x2.
        // Top-left: (6.071, 6.071)
        let piece = PlacedPiece(
            x: 6.07106,
            y: 6.07106,
            lengthMm: 2,
            widthMm: 2,
            label: "Center",
            source: .stock,
            status: .installed,
            rotation: 0
        )

        let transformed = transform.transformBack(piece)

        // Transformed piece should have center at (5, 5)
        let txCenter = transformed.x + transformed.lengthMm/2
        let tyCenter = transformed.y + transformed.widthMm/2

        XCTAssertEqual(txCenter, 5.0, accuracy: 0.001)
        XCTAssertEqual(tyCenter, 5.0, accuracy: 0.001)

        // Transformed rotation should be 45
        XCTAssertEqual(transformed.rotation, 45.0, accuracy: 0.001)
    }

    func testZeroRotation() {
        let original = RoomSettings(lengthMm: 100, widthMm: 50, expansionGapMm: 0)
        let transform = LayoutTransform(room: original, angleDegrees: 0)

        let rotated = transform.rotatedRoom(from: original)
        XCTAssertEqual(rotated.lengthMm, 100, accuracy: 0.001)
        XCTAssertEqual(rotated.widthMm, 50, accuracy: 0.001)

        let piece = PlacedPiece(x: 10, y: 10, lengthMm: 20, widthMm: 5, label: "P", source: .stock, status: .installed, rotation: 0)
        let transformed = transform.transformBack(piece)

        XCTAssertEqual(transformed.x, 10, accuracy: 0.001)
        XCTAssertEqual(transformed.y, 10, accuracy: 0.001)
        XCTAssertEqual(transformed.rotation, 0, accuracy: 0.001)
    }
}
