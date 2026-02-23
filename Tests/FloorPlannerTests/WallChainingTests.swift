//
//  WallChainingTests.swift
//  FloorPlannerTests
//
//  Unit tests for the chainWallSegments polygon-extraction algorithm.
//

import XCTest
@testable import FloorPlanner

final class WallChainingTests: XCTestCase {

    // MARK: - Empty / trivial inputs

    func testEmptySegments() {
        let result = chainWallSegments([])
        XCTAssertTrue(result.isEmpty)
    }

    func testSingleSegment() {
        let seg = [(FloorPoint(0, 0), FloorPoint(1, 0))]
        let result = chainWallSegments(seg)
        // Only two endpoints — not a valid polygon, but we still get the two points
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], FloorPoint(0, 0))
        XCTAssertEqual(result[1], FloorPoint(1, 0))
    }

    // MARK: - Simple rectangular room (4 walls, endpoints share corners)

    func testRectangularRoomInOrder() {
        // 4×3 m room, walls provided in sequence
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(4, 0)),   // bottom
            (FloorPoint(4, 0), FloorPoint(4, 3)),   // right
            (FloorPoint(4, 3), FloorPoint(0, 3)),   // top
            (FloorPoint(0, 3), FloorPoint(0, 0)),   // left (closes back to start)
        ]
        let result = chainWallSegments(segments)
        // Closing vertex should be removed → 4 unique corners
        XCTAssertEqual(result.count, 4)
    }

    func testRectangularRoomShuffled() {
        // Same room, walls in scrambled order — chaining must still produce a 4-vertex polygon
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(4, 3), FloorPoint(0, 3)),   // top
            (FloorPoint(0, 3), FloorPoint(0, 0)),   // left
            (FloorPoint(0, 0), FloorPoint(4, 0)),   // bottom
            (FloorPoint(4, 0), FloorPoint(4, 3)),   // right
        ]
        let result = chainWallSegments(segments)
        XCTAssertEqual(result.count, 4)
    }

    func testRectangularRoomReversedEndpoints() {
        // Each wall's endpoints are in reverse order — algorithm should handle both directions
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(4, 0), FloorPoint(0, 0)),   // bottom (reversed)
            (FloorPoint(4, 3), FloorPoint(4, 0)),   // right (reversed)
            (FloorPoint(0, 3), FloorPoint(4, 3)),   // top (reversed)
            (FloorPoint(0, 0), FloorPoint(0, 3)),   // left (reversed)
        ]
        let result = chainWallSegments(segments)
        XCTAssertEqual(result.count, 4)
    }

    // MARK: - L-shaped room (6 walls)

    func testLShapedRoom() {
        // L-shape: 6×4 with a 2×2 notch removed from one corner
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(6, 0)),
            (FloorPoint(6, 0), FloorPoint(6, 4)),
            (FloorPoint(6, 4), FloorPoint(2, 4)),
            (FloorPoint(2, 4), FloorPoint(2, 2)),
            (FloorPoint(2, 2), FloorPoint(0, 2)),
            (FloorPoint(0, 2), FloorPoint(0, 0)),
        ]
        let result = chainWallSegments(segments)
        XCTAssertEqual(result.count, 6)
    }

    // MARK: - Closing-vertex removal

    func testClosingVertexIsRemoved() {
        // The last segment connects back to the first point → duplicate should be dropped
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(1, 0)),
            (FloorPoint(1, 0), FloorPoint(1, 1)),
            (FloorPoint(1, 1), FloorPoint(0, 1)),
            (FloorPoint(0, 1), FloorPoint(0, 0)),   // closes polygon
        ]
        let result = chainWallSegments(segments)
        // Closing duplicate should be removed → 4 corners
        XCTAssertEqual(result.count, 4)
        // First vertex must NOT equal last vertex
        XCTAssertNotEqual(result.first, result.last)
    }

    // MARK: - Tolerance edge cases

    func testSegmentExactlyAtToleranceIsAccepted() {
        // Gap of exactly the default tolerance (0.15 m) should connect
        let gap: Float = 0.15
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(4, 0)),
            (FloorPoint(4 + gap, 0), FloorPoint(4 + gap, 3)), // tip starts at exact tolerance
            (FloorPoint(4 + gap, 3), FloorPoint(0, 3)),
            (FloorPoint(0, 3), FloorPoint(0, 0)),
        ]
        let result = chainWallSegments(segments, tolerance: gap)
        // All 4 segments chained (closing vertex removed) → 4 unique corners
        XCTAssertEqual(result.count, 4)
    }

    func testDisconnectedSegmentBreaksChain() {
        // One segment is far away — chaining should stop before it
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(4, 0)),
            (FloorPoint(100, 100), FloorPoint(101, 100)),  // completely disconnected
            (FloorPoint(4, 0), FloorPoint(4, 3)),
        ]
        // Chain: (0,0)→(4,0) then (4,0)→(4,3) — the disconnected segment is skipped
        let result = chainWallSegments(segments)
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - Custom tolerance

    func testCustomToleranceRejectsLargerGap() {
        // Default tolerance 0.15 m but this gap is 0.2 m — should break with tight tolerance
        let segments: [(FloorPoint, FloorPoint)] = [
            (FloorPoint(0, 0), FloorPoint(4, 0)),
            (FloorPoint(4.2, 0), FloorPoint(4.2, 3)),  // 0.2 m gap
        ]
        let tight = chainWallSegments(segments, tolerance: 0.15)
        XCTAssertEqual(tight.count, 2)   // second segment not chained

        let loose = chainWallSegments(segments, tolerance: 0.25)
        XCTAssertEqual(loose.count, 3)   // second segment IS chained
    }
}
