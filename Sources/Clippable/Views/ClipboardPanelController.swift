import AppKit
import SwiftUI

class ClickablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Esc to close
        if event.keyCode == 53 {
            orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}

class ClipboardPanelController: NSObject {
    private var panel: ClickablePanel?
    private var monitor: ClipboardMonitor
    private var previousApp: NSRunningApplication?

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
        super.init()
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
            let x = frame.midX - panelWidth / 2
            let y = frame.minY - panelHeight
            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        } else {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - panelWidth / 2
                let y = screenFrame.midY - panelHeight / 2 + 50
                panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
            }
        }

        previousApp = NSWorkspace.shared.frontmostApplication

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        panel?.orderOut(nil)
        previousApp?.activate(options: [])
        previousApp = nil
    }

    private func createPanel() {
        let panel = ClickablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = true
        panel.animationBehavior = .utilityWindow
        panel.backgroundColor = .clear
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let hostingView = NSHostingView(
            rootView: ClipboardHistoryView(monitor: monitor) { [weak self] in
                self?.hidePanel()
            }
        )
        panel.contentView = hostingView

        self.panel = panel
    }
}

extension ClipboardPanelController: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        // Don't auto-close — let user dismiss via Esc, menu bar click, or hotkey
    }
}
