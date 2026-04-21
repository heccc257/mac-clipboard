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
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        if let monitor = clipboardMonitor {
            StorageManager.shared.save(history: monitor.history)
        }
        hotkeyManager?.unregister()
    }
}

extension Notification.Name {
    static let toggleClipboardPanel = Notification.Name("toggleClipboardPanel")
}
