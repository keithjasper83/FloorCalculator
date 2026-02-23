//
//  WallChaining.swift
//  FloorPlanner
//
//  Pure-Swift polygon extraction from wall endpoint segments.
//  Extracted from the RoomPlan/ARKit layer to allow unit testing
//  without a RoomPlan dependency.
//

import Foundation

/// A 2D point in the room's floor plane.
/// x = world X axis, y = world Z axis, values in metres.
struct FloorPoint: Equatable {
    let x: Float
    let y: Float
    init(_ x: Float, _ y: Float) { self.x = x; self.y = y }
}

/// Greedy segment-chaining algorithm that orders wall-endpoint pairs into a polygon.
///
/// Each wall provides two endpoints. The function greedily finds the next unconnected
/// segment whose nearer endpoint is within `tolerance` metres of the current chain tip,
/// and appends the far endpoint. The duplicate closing vertex is removed if present.
///
/// - Parameters:
///   - segments: Wall endpoint pairs, values in metres.
///   - tolerance: Maximum gap between adjacent corners (default 150 mm = 0.15 m).
/// - Returns: Ordered polygon vertices, or an empty array when the input is empty.
internal func chainWallSegments(
    _ segments: [(FloorPoint, FloorPoint)],
    tolerance: Float = 0.15
) -> [FloorPoint] {
    guard !segments.isEmpty else { return [] }

    var remaining = segments
    var chain = [remaining[0].0, remaining[0].1]
    remaining.removeFirst()

    while !remaining.isEmpty {
        let tip = chain.last!
        var bestIndex = -1
        var bestDist = tolerance
        // true  → seg.0 matched tip, so add seg.1 as next vertex
        // false → seg.1 matched tip, so add seg.0 as next vertex
        var useP2AsNext = false

        for (i, seg) in remaining.enumerated() {
            let d0 = hypot(tip.x - seg.0.x, tip.y - seg.0.y)
            let d1 = hypot(tip.x - seg.1.x, tip.y - seg.1.y)
            let (closerDist, addP2) = d0 <= d1 ? (d0, true) : (d1, false)
            if closerDist <= bestDist {
                bestDist = closerDist
                bestIndex = i
                useP2AsNext = addP2
            }
        }

        guard bestIndex >= 0 else { break }
        let seg = remaining[bestIndex]
        chain.append(useP2AsNext ? seg.1 : seg.0)
        remaining.remove(at: bestIndex)
    }

    // Drop the closing vertex if it matches the first (polygon is implicitly closed).
    if chain.count > 1 && hypot(chain[0].x - chain.last!.x, chain[0].y - chain.last!.y) <= tolerance {
        chain.removeLast()
    }

    return chain
}
