import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private weak var panelController: ClipboardPanelController?

    init(panelController: ClipboardPanelController) {
        self.panelController = panelController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clippable")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showImageMenu()
        } else {
            panelController?.togglePanel(relativeTo: statusItem.button?.window?.frame)
        }
    }

    private func showImageMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Get sendable image items (max 10)
        let imageItems = ClipboardMonitor.shared.history
            .filter { $0.isSendableImage }
            .prefix(10)

        if imageItems.isEmpty {
            let noItems = NSMenuItem(title: "No images/files", action: nil, keyEquivalent: "")
            noItems.isEnabled = false
            menu.addItem(noItems)
        } else {
            let header = NSMenuItem(title: "Images & Files", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for item in imageItems {
                let title = menuTitle(for: item)
                let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")

                // Submenu with actions
                let submenu = NSMenu()

                let sendItem = NSMenuItem(title: "Send to Remote", action: #selector(sendItemToRemote(_:)), keyEquivalent: "")
                sendItem.target = self
                sendItem.representedObject = item
                submenu.addItem(sendItem)

                let copyItem = NSMenuItem(title: "Copy to Clipboard", action: #selector(copyItem(_:)), keyEquivalent: "")
                copyItem.target = self
                copyItem.representedObject = item
                submenu.addItem(copyItem)

                menuItem.submenu = submenu

                // Add thumbnail for image type
                if item.type == .image,
                   let fileName = item.imageFileName,
                   let data = StorageManager.shared.loadImageData(fileName: fileName),
                   let nsImage = NSImage(data: data) {
                    let thumb = NSImage(size: NSSize(width: 20, height: 20))
                    thumb.lockFocus()
                    nsImage.draw(in: NSRect(x: 0, y: 0, width: 20, height: 20))
                    thumb.unlockFocus()
                    menuItem.image = thumb
                } else {
                    menuItem.image = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
                }

                menu.addItem(menuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Clippable", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func menuTitle(for item: ClipboardItem) -> String {
        let time = relativeTime(item.timestamp)
        switch item.type {
        case .image:
            return "Image  (\(time))"
        case .filePaths:
            if let paths = item.filePaths, let first = paths.first {
                let name = (first as NSString).lastPathComponent
                return "\(name)  (\(time))"
            }
            return "File  (\(time))"
        case .text:
            return item.previewText
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    @objc private func sendItemToRemote(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipboardItem else { return }
        let paths = item.sendableFilePaths
        guard !paths.isEmpty else { return }

        debugLog("Menu: sendToRemote \(paths)")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let connections = RemoteManager.shared.detectVSCodeConnections()
            guard let host = connections.first?.host else {
                debugLog("No VSCode SSH connection")
                DispatchQueue.main.async {
                    self?.showAlert(title: "Failed", message: "No VSCode SSH connection detected")
                }
                return
            }

            RemoteManager.shared.sendFiles(localPaths: paths, to: host) { success, message in
                debugLog("SCP: success=\(success) msg=\(message)")
                DispatchQueue.main.async {
                    self?.showAlert(
                        title: success ? "Sent!" : "Failed",
                        message: message
                    )
                }
            }
        }
    }

    @objc private func copyItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipboardItem else { return }
        ClipboardMonitor.shared.copyToClipboard(item: item)
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = title == "Failed" ? .warning : .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func clearHistory() {
        ClipboardMonitor.shared.clearHistory()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
