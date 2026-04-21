import Foundation
import AppKit

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: ClipboardItemType
    let textContent: String?
    let imageFileName: String?
    let filePaths: [String]?
    let sourceAppBundleID: String?
    let contentHash: String

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "webp", "heic", "heif"]

    /// Whether this item is sendable to a remote host (image or image files)
    var isSendableImage: Bool {
        if type == .image { return true }
        if type == .filePaths, let paths = filePaths {
            return paths.contains { path in
                let ext = (path as NSString).pathExtension.lowercased()
                return Self.imageExtensions.contains(ext)
            }
        }
        return false
    }

    /// Local file paths for sending (works for both .image and .filePaths types)
    var sendableFilePaths: [String] {
        switch type {
        case .image:
            if let fileName = imageFileName {
                return [StorageManager.shared.imageFilePath(fileName: fileName)]
            }
            return []
        case .filePaths:
            return filePaths?.filter { path in
                let ext = (path as NSString).pathExtension.lowercased()
                return Self.imageExtensions.contains(ext)
            } ?? []
        case .text:
            return []
        }
    }

    var displayText: String {
        switch type {
        case .text:
            return textContent ?? ""
        case .image:
            return "[Image]"
        case .filePaths:
            if let paths = filePaths {
                return paths.joined(separator: ", ")
            }
            return "[Files]"
        }
    }

    var previewText: String {
        let text = displayText
        if text.count > 100 {
            return String(text.prefix(100)) + "..."
        }
        return text
    }

    func matches(_ query: String) -> Bool {
        let lowered = query.lowercased()
        switch type {
        case .text:
            return textContent?.lowercased().contains(lowered) ?? false
        case .image:
            return "image".contains(lowered)
        case .filePaths:
            return filePaths?.contains(where: { $0.lowercased().contains(lowered) }) ?? false
        }
    }

    static func computeHash(for data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            var h: UInt64 = 0xcbf29ce484222325
            for byte in buffer {
                h ^= UInt64(byte)
                h &*= 0x100000001b3
            }
            withUnsafeMutableBytes(of: &h) { hashBytes in
                for i in 0..<min(8, hash.count) {
                    hash[i] = hashBytes[i]
                }
            }
        }
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}
