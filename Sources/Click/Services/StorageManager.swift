import Foundation

class StorageManager {
    static let shared = StorageManager()

    private let appSupportDir: URL
    private let historyFileURL: URL
    private let imagesDir: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportDir = appSupport.appendingPathComponent("Click", isDirectory: true)
        historyFileURL = appSupportDir.appendingPathComponent("history.json")
        imagesDir = appSupportDir.appendingPathComponent("images", isDirectory: true)

        // Create directories
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }

    func loadHistory() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: historyFileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipboardItem].self, from: data)) ?? []
    }

    func save(history: [ClipboardItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(history) else { return }
        try? data.write(to: historyFileURL, options: .atomic)
    }

    func saveImageData(_ data: Data, fileName: String) {
        let fileURL = imagesDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL, options: .atomic)
    }

    func loadImageData(fileName: String) -> Data? {
        let fileURL = imagesDir.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    func clearImages() {
        if let files = try? FileManager.default.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
