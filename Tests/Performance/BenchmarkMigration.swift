import Foundation

struct MockProject: Codable {
    var id: UUID
    var name: String
    var data: [String] // Large array to simulate project complexity
    var createdAt: Date

    static func random() -> MockProject {
        MockProject(
            id: UUID(),
            name: "Project \(UUID().uuidString)",
            data: (0..<100).map { _ in UUID().uuidString }, // ~3.6KB + overhead
            createdAt: Date()
        )
    }
}

let fileCount = 500
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("benchmark_migration_\(UUID().uuidString)")

do {
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("Failed to create temp dir: \(error)")
    exit(1)
}

print("Generating \(fileCount) files...")
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601

for i in 0..<fileCount {
    let project = MockProject.random()
    let url = tempDir.appendingPathComponent("project_\(i).json")
    do {
        let data = try encoder.encode(project)
        try data.write(to: url)
    } catch {
        print("Failed to write file: \(error)")
    }
}

// Get file list
guard let urls = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) else {
    print("Failed to list files")
    exit(1)
}

print("Starting Sequential Benchmark...")
let startSeq = Date()

for url in urls {
    autoreleasepool {
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let _ = try decoder.decode(MockProject.self, from: data)

            // Simulate file move
            let destination = url.deletingPathExtension().appendingPathExtension("json.migrated")
            // In real app we move, here just check
        } catch {
            print("Error: \(error)")
        }
    }
}

let endSeq = Date()
let timeSeq = endSeq.timeIntervalSince(startSeq)
print("Sequential Time: \(String(format: "%.4f", timeSeq))s")

print("Starting Parallel Benchmark...")

// Reset logic (file moves not simulated to allow re-run)
// Actually parallel run should operate on same set, but files are not modified in seq run above (except destination logic commented out).

let startPar = Date()

DispatchQueue.concurrentPerform(iterations: urls.count) { index in
    let url = urls[index]
    autoreleasepool {
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let _ = try decoder.decode(MockProject.self, from: data)
        } catch {
            print("Error: \(error)")
        }
    }
}

let endPar = Date()
let timePar = endPar.timeIntervalSince(startPar)
print("Parallel Time:   \(String(format: "%.4f", timePar))s")
print("Improvement:     \(String(format: "%.2f", timeSeq / timePar))x")

// Cleanup
try? FileManager.default.removeItem(at: tempDir)
