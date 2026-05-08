import AppKit
import Foundation

class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var history: [ClipboardItem] = []

    private var pollTimer: Timer?
    private var lastChangeCount: Int = 0
    var isInternalCopy = false

    private let maxHistoryCount = 500

    // Pasteboard reads go through the system pboard IPC server, which is
    // single-threaded across processes. Doing them on the main thread while
    // another app (e.g. VSCode/Electron) is also accessing the clipboard can
    // stall both sides. Read on a background queue and only touch @Published
    // state back on main.
    private let readQueue = DispatchQueue(label: "com.clippable.pasteboard-read", qos: .utility)

    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func startMonitoring() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func loadHistory(from storage: StorageManager) {
        history = storage.loadHistory()
    }

    func clearHistory() {
        history.removeAll()
        StorageManager.shared.save(history: history)
        StorageManager.shared.clearImages()
    }

    func copyToClipboard(item: ClipboardItem) {
        isInternalCopy = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let fileName = item.imageFileName,
               let imageData = StorageManager.shared.loadImageData(fileName: fileName) {
                pasteboard.setData(imageData, forType: .png)
            }
        case .filePaths:
            if let paths = item.filePaths {
                let urls = paths.compactMap { URL(fileURLWithPath: $0) }
                pasteboard.writeObjects(urls as [NSURL])
            }
        }
    }

    private func checkForChanges() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if isInternalCopy {
            isInternalCopy = false
            return
        }

        // Debounce briefly so the writing app finishes posting all flavors
        // before we touch the pasteboard, then read off the main thread.
        readQueue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            // Re-check the change count: if another change has already
            // landed, drop this read — the next tick will pick it up.
            let pasteboard = NSPasteboard.general
            guard pasteboard.changeCount == currentCount else { return }

            guard let item = self.readPasteboard(pasteboard) else { return }

            DispatchQueue.main.async {
                // Deduplicate: skip if same hash as most recent
                if let last = self.history.first, last.contentHash == item.contentHash {
                    return
                }
                self.history.insert(item, at: 0)
                if self.history.count > self.maxHistoryCount {
                    self.history = Array(self.history.prefix(self.maxHistoryCount))
                }
                self.scheduleSave()
            }
        }
    }

    /// Read the current pasteboard. Safe to call off the main thread.
    /// Uses `pasteboard.types` for cheap type detection so we never request
    /// data flavors the source app didn't advertise — Electron apps like
    /// VSCode lazily materialize promised types and a blind `.tiff` read can
    /// stall their main thread.
    private func readPasteboard(_ pasteboard: NSPasteboard) -> ClipboardItem? {
        let availableTypes = Set(pasteboard.types ?? [])
        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        // Check for file URLs first — only if URL types are advertised.
        let urlTypes: Set<NSPasteboard.PasteboardType> = [.fileURL, .URL]
        if !availableTypes.isDisjoint(with: urlTypes),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
               .urlReadingFileURLsOnly: true
           ]) as? [URL], !urls.isEmpty {
            let paths = urls.map { $0.path }
            let hashData = paths.joined(separator: "\n").data(using: .utf8) ?? Data()
            return ClipboardItem(
                id: UUID(),
                timestamp: Date(),
                type: .filePaths,
                textContent: nil,
                imageFileName: nil,
                filePaths: paths,
                sourceAppBundleID: sourceApp,
                contentHash: ClipboardItem.computeHash(for: hashData)
            )
        }

        // Check for images — only if image types are advertised. Prefer PNG
        // to avoid forcing a TIFF materialization when both are present.
        let imageTypes: Set<NSPasteboard.PasteboardType> = [.png, .tiff]
        if !availableTypes.isDisjoint(with: imageTypes) {
            let rawImageData: Data? = availableTypes.contains(.png)
                ? pasteboard.data(forType: .png)
                : pasteboard.data(forType: .tiff)

            if let imageData = rawImageData {
                // Skip very large images (>10MB)
                guard imageData.count <= 10_000_000 else { return nil }

                let fileName = UUID().uuidString + ".png"
                // Convert to PNG if TIFF
                let pngData: Data
                if let img = NSImage(data: imageData),
                   let tiffRep = img.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffRep),
                   let png = bitmapRep.representation(using: .png, properties: [:]) {
                    pngData = png
                } else {
                    pngData = imageData
                }

                StorageManager.shared.saveImageData(pngData, fileName: fileName)

                return ClipboardItem(
                    id: UUID(),
                    timestamp: Date(),
                    type: .image,
                    textContent: nil,
                    imageFileName: fileName,
                    filePaths: nil,
                    sourceAppBundleID: sourceApp,
                    contentHash: ClipboardItem.computeHash(for: pngData)
                )
            }
        }

        // Check for text — only if a string flavor is advertised.
        if availableTypes.contains(.string),
           let text = pasteboard.string(forType: .string), !text.isEmpty {
            let hashData = text.data(using: .utf8) ?? Data()
            return ClipboardItem(
                id: UUID(),
                timestamp: Date(),
                type: .text,
                textContent: text,
                imageFileName: nil,
                filePaths: nil,
                sourceAppBundleID: sourceApp,
                contentHash: ClipboardItem.computeHash(for: hashData)
            )
        }

        return nil
    }

    private var saveWorkItem: DispatchWorkItem?

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            StorageManager.shared.save(history: self.history)
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }
}
