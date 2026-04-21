import AppKit
import SwiftUI

class ClipboardPanelController {
    private var panel: NSPanel?
    private var monitor: ClipboardMonitor
    private var clickOutsideMonitor: Any?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
    }

    func togglePanel(relativeTo frame: NSRect? = nil) {
        if let panel = panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel(relativeTo: frame)
        }
    }

    func showPanel(relativeTo statusBarFrame: NSRect? = nil) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        let panelWidth: CGFloat = 380
        let panelHeight: CGFloat = 500

        if let frame = statusBarFrame {
            // Position below menu bar icon
            let x = frame.midX - panelWidth / 2
            let y = frame.minY - panelHeight
            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        } else {
            // Position at center of screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - panelWidth / 2
                let y = screenFrame.midY - panelHeight / 2 + 50
                panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
            }
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Monitor for clicks outside panel to dismiss
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePanel()
        }
    }

    func hidePanel() {
        panel?.orderOut(nil)
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.backgroundColor = .clear

        let hostingView = NSHostingView(
            rootView: ClipboardHistoryView(monitor: monitor) { [weak self] in
                self?.hidePanel()
            }
        )
        panel.contentView = hostingView

        // Close on Escape
        panel.isReleasedWhenClosed = false

        self.panel = panel
    }
}
