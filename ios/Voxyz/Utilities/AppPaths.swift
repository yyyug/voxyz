import Foundation

enum AppPaths {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var recordingsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Recordings")
        ensureDirectory(url)
        return url
    }

    static var exportsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Exports")
        ensureDirectory(url)
        return url
    }

    static var modelsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Models")
        ensureDirectory(url)
        return url
    }

    private static func ensureDirectory(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
