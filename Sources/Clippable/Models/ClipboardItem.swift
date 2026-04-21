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
