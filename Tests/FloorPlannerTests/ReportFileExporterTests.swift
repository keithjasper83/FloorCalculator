import XCTest
@testable import FloorPlanner

final class ReportFileExporterTests: XCTestCase {

    func testWriteFiles_Success() {
        let files: [(name: String, data: Data)] = [
            ("file1.csv", Data("content1".utf8)),
            ("file2.csv", Data("content2".utf8))
        ]
        let directoryURL = URL(fileURLWithPath: "/tmp/reports")

        var exporter = ReportFileExporter()
        // Inject a successful write closure
        exporter.fileWriter = { data, url, options in
            // Simulate success: do nothing
        }

        let resultURLs = exporter.writeFiles(files: files, to: directoryURL)

        XCTAssertEqual(resultURLs.count, 2)
        XCTAssertEqual(resultURLs[0].lastPathComponent, "file1.csv")
        XCTAssertEqual(resultURLs[1].lastPathComponent, "file2.csv")
    }

    func testWriteFiles_SkipsFailedWrites() {
        let files: [(name: String, data: Data)] = [
            ("success.csv", Data("content".utf8)),
            ("fail.csv", Data("content".utf8)),
            ("success2.csv", Data("content".utf8))
        ]
        let directoryURL = URL(fileURLWithPath: "/tmp/reports")

        var exporter = ReportFileExporter()
        // Inject a closure that fails for specific files
        exporter.fileWriter = { data, url, options in
            if url.lastPathComponent == "fail.csv" {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            // Otherwise simulate success
        }

        let resultURLs = exporter.writeFiles(files: files, to: directoryURL)

        XCTAssertEqual(resultURLs.count, 2)
        XCTAssertEqual(resultURLs[0].lastPathComponent, "success.csv")
        XCTAssertEqual(resultURLs[1].lastPathComponent, "success2.csv")
        XCTAssertFalse(resultURLs.contains(where: { $0.lastPathComponent == "fail.csv" }))
    }
}
