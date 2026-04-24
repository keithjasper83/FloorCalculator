import Foundation

/// Handles the export of report files to a given directory.
/// Uses dependency injection for file writing to allow for isolated unit testing
/// of success and failure scenarios without modifying actual files.
struct ReportFileExporter {
    /// Closure used to write data to a URL.
    /// Can be overridden for testing to simulate failures.
    var fileWriter: (Data, URL, Data.WritingOptions) throws -> Void = { data, url, options in
        try data.write(to: url, options: options)
    }

    /// Writes a list of files to the specified directory.
    /// - Parameters:
    ///   - files: Array of tuples containing the file name and its corresponding Data.
    ///   - directory: The destination URL directory.
    /// - Returns: An array of URLs representing the files that were successfully written.
    func writeFiles(files: [(name: String, data: Data)], to directory: URL) -> [URL] {
        var successfulURLs: [URL] = []

        for file in files {
            let url = directory.appendingPathComponent(file.name)
            do {
                try fileWriter(file.data, url, .atomic)
                successfulURLs.append(url)
            } catch {
                // Silently skip failed writes per existing behavior,
                // but this behavior is now testable.
            }
        }

        return successfulURLs
    }
}
