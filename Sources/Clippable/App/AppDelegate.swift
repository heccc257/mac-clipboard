import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var clipboardMonitor: ClipboardMonitor?
    private var hotkeyManager: HotkeyManager?
    private var panelController: ClipboardPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let storageManager = StorageManager.shared
        clipboardMonitor = ClipboardMonitor.shared
        clipboardMonitor?.loadHistory(from: storageManager)
        clipboardMonitor?.startMonitoring()

        panelController = ClipboardPanelController(monitor: clipboardMonitor!)

        statusBarController = StatusBarController(panelController: panelController!)

        hotkeyManager = HotkeyManager.shared
        hotkeyManager?.panelController = panelController

        NotificationCenter.default.addObserver(
            forName: .toggleClipboardPanel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.panelController?.togglePanel()
        }

        NotificationCenter.default.addObserver(
            forName: .sendToRemote,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sendLatestImageToRemote()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        if let monitor = clipboardMonitor {
            StorageManager.shared.save(history: monitor.history)
        }
        hotkeyManager?.unregister()
    }

    private func sendLatestImageToRemote() {
        guard let item = ClipboardMonitor.shared.history.first(where: { $0.isSendableImage }) else {
            debugLog("No sendable image in history")
            return
        }

        let paths = item.sendableFilePaths
        guard !paths.isEmpty else { return }

        debugLog("Cmd+Shift+S: sending \(paths)")

        DispatchQueue.global(qos: .userInitiated).async {
            let connections = RemoteManager.shared.detectVSCodeConnections()
            debugLog("Connections: \(connections.map(\.host))")

            guard let host = connections.first?.host else {
                debugLog("No VSCode SSH connection")
                return
            }

            RemoteManager.shared.sendFiles(localPaths: paths, to: host) { success, message in
                debugLog("SCP result: success=\(success) message=\(message)")
            }
        }
    }
}

extension Notification.Name {
    static let toggleClipboardPanel = Notification.Name("toggleClipboardPanel")
    static let sendToRemote = Notification.Name("sendToRemote")
}
