import Foundation

struct RoomPoint: Codable, Equatable, Identifiable {
    var id = UUID()
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Generate test data
var points: [RoomPoint] = []
for i in 0..<10000 {
    points.append(RoomPoint(x: Double.random(in: 0...10000), y: Double.random(in: 0...10000)))
}

// Method 1: Current
func method1() {
    let start = Date()
    for _ in 0..<100 {
        let minX = points.map { $0.x }.min() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
    }
    print("Method 1: \(Date().timeIntervalSince(start))s")
}

// Method 2: Single pass
func method2() {
    let start = Date()
    for _ in 0..<100 {
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        for point in points {
            if point.x < minX { minX = point.x }
            if point.y < minY { minY = point.y }
        }
        if minX == .greatestFiniteMagnitude {
            minX = 0
            minY = 0
        }
    }
    print("Method 2: \(Date().timeIntervalSince(start))s")
}

method1()
method2()
