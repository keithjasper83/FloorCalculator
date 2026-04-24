import Foundation

struct RoomPoint {
    var x: Double
    var y: Double
}

struct PolygonRoom {
    var polygonPoints: [RoomPoint]

    // Original implementation
    func pointInPolygon(x: Double, y: Double) -> Bool {
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

    // Bounding box implementation
    let minX: Double
    let maxX: Double
    let minY: Double
    let maxY: Double

    init(points: [RoomPoint]) {
        self.polygonPoints = points

        var min_X = Double.infinity
        var max_X = -Double.infinity
        var min_Y = Double.infinity
        var max_Y = -Double.infinity

        for p in points {
            if p.x < min_X { min_X = p.x }
            if p.x > max_X { max_X = p.x }
            if p.y < min_Y { min_Y = p.y }
            if p.y > max_Y { max_Y = p.y }
        }

        self.minX = min_X
        self.maxX = max_X
        self.minY = min_Y
        self.maxY = max_Y
    }

    func pointInPolygonOptimized(x: Double, y: Double) -> Bool {
        // Fast bounding box check
        guard x >= minX && x <= maxX && y >= minY && y <= maxY else {
            return false
        }

        guard polygonPoints.count >= 3 else { return false }

        var inside = false
        let n = polygonPoints.count

        var j = n - 1
        for i in 0..<n {
            let xi = polygonPoints[i].x
            let yi = polygonPoints[i].y
            let xj = polygonPoints[j].x
            let yj = polygonPoints[j].y

            let intersect = ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            if intersect {
                inside = !inside
            }
            j = i
        }

        return inside
    }

    func pointInPolygonHighlyOptimized(x: Double, y: Double) -> Bool {
        // Fast bounding box check
        guard x >= minX && x <= maxX && y >= minY && y <= maxY else {
            return false
        }

        guard polygonPoints.count >= 3 else { return false }

        var inside = false
        let n = polygonPoints.count

        var j = n - 1
        for i in 0..<n {
            let xi = polygonPoints[i].x
            let yi = polygonPoints[i].y
            let yj = polygonPoints[j].y

            // Only proceed if y is between yi and yj
            if (yi > y) != (yj > y) {
                let xj = polygonPoints[j].x

                // If both points are to the right of x, the ray definitely intersects
                if xi > x && xj > x {
                    inside = !inside
                }
                // If the edge spans across x, calculate exact intersection
                else if xi >= x || xj >= x {
                    // Only compute division if necessary
                    let intersectX = (xj - xi) * (y - yi) / (yj - yi) + xi
                    if x < intersectX {
                        inside = !inside
                    }
                }
            }
            j = i
        }

        return inside
    }
}

// Generate complex polygon (circle-like)
var points: [RoomPoint] = []
let numPoints = 50 // Typical number of points for a complex room
let radius = 1000.0
let center = RoomPoint(x: 1000, y: 1000)

for i in 0..<numPoints {
    let angle = Double(i) * 2.0 * .pi / Double(numPoints)
    points.append(RoomPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
}

let room = PolygonRoom(points: points)

// Generate test points: many outside, some inside
// In a grid layout engine, points are tested in a grid over the bounding box + expansion gap
var testPoints: [RoomPoint] = []
for x in stride(from: -500.0, to: 2500.0, by: 50.0) {
    for y in stride(from: -500.0, to: 2500.0, by: 50.0) {
        testPoints.append(RoomPoint(x: x, y: y))
    }
}

// Run original
let startOriginal = CFAbsoluteTimeGetCurrent()
var insideOriginal = 0
for _ in 0..<1000 {
    for p in testPoints {
        if room.pointInPolygon(x: p.x, y: p.y) {
            insideOriginal += 1
        }
    }
}
let timeOriginal = CFAbsoluteTimeGetCurrent() - startOriginal

// Run highly optimized
let startHighlyOptimized = CFAbsoluteTimeGetCurrent()
var insideHighlyOptimized = 0
for _ in 0..<1000 {
    for p in testPoints {
        if room.pointInPolygonHighlyOptimized(x: p.x, y: p.y) {
            insideHighlyOptimized += 1
        }
    }
}
let timeHighlyOptimized = CFAbsoluteTimeGetCurrent() - startHighlyOptimized


print("Original: \(timeOriginal) seconds, inside: \(insideOriginal)")
print("Bounding Box + Math Opt: \(timeHighlyOptimized) seconds, inside: \(insideHighlyOptimized)")
