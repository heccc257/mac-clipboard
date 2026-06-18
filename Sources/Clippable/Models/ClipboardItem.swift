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
        fuzzyScore(query) != nil
    }

    /// Fuzzy match score against `query`. Returns `nil` when there is no match.
    /// Higher scores indicate a better match (used to rank search results).
    /// A contiguous substring match ranks above a scattered subsequence match,
    /// and earlier / more consecutive matches score higher.
    func fuzzyScore(_ query: String) -> Int? {
        let q = query.lowercased()
        if q.isEmpty { return 0 }

        let target: String
        switch type {
        case .text:
            target = (textContent ?? "").lowercased()
        case .image:
            target = "image"
        case .filePaths:
            target = (filePaths?.joined(separator: " ") ?? "").lowercased()
        }

        // Exact substring: strongly preferred, earlier matches rank higher.
        if let range = target.range(of: q) {
            let pos = target.distance(from: target.startIndex, to: range.lowerBound)
            return 10_000 - min(pos, 9_000)
        }

        // Subsequence fuzzy match: every query char must appear in order.
        let targetChars = Array(target)
        let queryChars = Array(q)
        var qi = 0
        var score = 0
        var lastMatchIndex = -2
        for (i, ch) in targetChars.enumerated() {
            guard qi < queryChars.count else { break }
            if ch == queryChars[qi] {
                score += (i == lastMatchIndex + 1) ? 5 : 1  // consecutive bonus
                lastMatchIndex = i
                qi += 1
            }
        }
        return qi == queryChars.count ? score : nil
    }

    /// Character offsets within `text` that match `query`, using the same
    /// substring-first then subsequence logic as `fuzzyScore`. Used to draw
    /// search highlights. Operates on the exact string being displayed so the
    /// highlighted positions line up with what the user sees.
    static func matchedIndices(in text: String, query: String) -> IndexSet {
        guard !query.isEmpty else { return IndexSet() }

        // Contiguous, case-insensitive substring match (preferred).
        if let range = text.range(of: query, options: .caseInsensitive) {
            let start = text.distance(from: text.startIndex, to: range.lowerBound)
            let len = text.distance(from: range.lowerBound, to: range.upperBound)
            return IndexSet(integersIn: start..<(start + len))
        }

        // Subsequence fallback: match query characters in order.
        let queryChars = Array(query.lowercased())
        var qi = 0
        var result = IndexSet()
        for (i, ch) in text.enumerated() {
            guard qi < queryChars.count else { break }
            if ch.lowercased() == String(queryChars[qi]) {
                result.insert(i)
                qi += 1
            }
        }
        return qi == queryChars.count ? result : IndexSet()
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
