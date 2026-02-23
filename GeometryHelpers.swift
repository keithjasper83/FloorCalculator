import Foundation

/// A simple 2D point in floor-plan world coordinates (meters) used during AR capture.
/// This is intentionally separate from RoomPoint (which is millimeters in app space).
public struct FloorPoint: Hashable, CustomStringConvertible {
    /// The x-coordinate in meters.
    public var x: Float
    /// The y-coordinate in meters.
    public var y: Float

    /// Creates a new FloorPoint with given x and y coordinates.
    /// - Parameters:
    ///   - x: The x-coordinate in meters.
    ///   - y: The y-coordinate in meters.
    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    /// A textual representation of the point.
    public var description: String { "(\(x), \(y))" }
}

/// Chains a set of unordered wall segments into an ordered polygonal path.
/// - Parameter segments: Array of line segments represented as pairs of FloorPoint endpoints.
/// - Returns: An ordered list of unique vertices representing the chained outline. If chaining fails, returns an empty array.
public func chainWallSegments(_ segments: [(FloorPoint, FloorPoint)]) -> [FloorPoint] {
    guard !segments.isEmpty else { return [] }

    // Build adjacency map of endpoints using a tolerance to merge near-identical points
    let tol: Float = 0.01 // 1 cm tolerance in meters

    // Helper to find or create a canonical point key
    func key(for p: FloorPoint) -> FloorPoint {
        // Quantize by tolerance to merge close points
        let qx = round(p.x / tol) * tol
        let qy = round(p.y / tol) * tol
        return FloorPoint(qx, qy)
    }

    var adjacency: [FloorPoint: Set<FloorPoint>] = [:]
    for (a, b) in segments {
        let ka = key(for: a)
        let kb = key(for: b)
        if ka == kb { continue }
        adjacency[ka, default: []].insert(kb)
        adjacency[kb, default: []].insert(ka)
    }

    // Find a starting point: prefer a vertex with degree 1 (open chain), else any
    let start: FloorPoint = adjacency.first(where: { $0.value.count == 1 })?.key
        ?? adjacency.keys.first!

    // Walk the graph to build an ordered chain; prefer not revisiting edges
    var chain: [FloorPoint] = [start]
    var visitedEdges: Set<[FloorPoint]> = [] // store undirected edge as sorted pair

    func edgeKey(_ u: FloorPoint, _ v: FloorPoint) -> [FloorPoint] {
        [u, v].sorted { ($0.x, $0.y) < ($1.x, $1.y) }
    }

    var current = start
    var previous: FloorPoint? = nil

    while let neighbors = adjacency[current], !neighbors.isEmpty {
        // Choose the next neighbor that does not revisit an already used edge and is not the immediate previous point if alternatives exist
        let options = neighbors.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var nextOpt: FloorPoint? = nil
        for n in options {
            if let prev = previous, n == prev { continue }
            let ekey = edgeKey(current, n)
            if !visitedEdges.contains(ekey) {
                nextOpt = n
                break
            }
        }
        // If all options exhausted, allow going back to previous if that closes the loop
        if nextOpt == nil, let prev = previous, neighbors.contains(prev) {
            nextOpt = prev
        }
        guard let next = nextOpt else { break }

        let ekey = edgeKey(current, next)
        if visitedEdges.contains(ekey) { break }
        visitedEdges.insert(ekey)

        if chain.last != next { chain.append(next) }
        previous = current
        current = next

        // Stop if we returned to start and have at least a triangle
        if next == start && chain.count >= 4 { // start repeats as last to close
            break
        }
    }

    // If closed, drop the duplicated last point for a simple vertex list
    if chain.count >= 2, chain.first == chain.last {
        chain.removeLast()
    }

    // Validate: at least 3 unique points
    let unique = Array(Set(chain))
    if unique.count < 3 {
        return []
    }

    return chain
}
