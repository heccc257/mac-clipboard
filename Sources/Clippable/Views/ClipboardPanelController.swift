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
        let visible = panel?.isVisible ?? false
        debugLog("togglePanel: panel=\(panel == nil ? "nil" : "exists") visible=\(visible) frame=\(String(describing: frame))")
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

        guard let panel = panel else {
            debugLog("showPanel: panel is nil after createPanel — aborting")
            return
        }

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

        // Do NOT call NSApp.activate(ignoringOtherApps:) here — it forces
        // macOS to switch the user to whichever Space the panel lives on,
        // overriding .canJoinAllSpaces. With .nonactivatingPanel + a high
        // window level, makeKeyAndOrderFront alone is enough.
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        let activeApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?"
        let screens = NSScreen.screens.map { "\($0.frame)" }.joined(separator: ", ")
        debugLog("showPanel: shown at \(panel.frame), isVisible=\(panel.isVisible), isKey=\(panel.isKeyWindow), level=\(panel.level.rawValue), alpha=\(panel.alphaValue), frontmost=\(activeApp), screens=[\(screens)]")
    }

    func hidePanel() {
        debugLog("hidePanel called")
        panel?.orderOut(nil)
        // .activateIgnoringOtherApps is the only reliable way to actually pull
        // the previous app to the front from a status-bar/accessory app.
        // Empty options frequently no-ops on recent macOS.
        previousApp?.activate(options: [.activateIgnoringOtherApps])
        previousApp = nil
    }

    private func createPanel() {
        let panel = ClickablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            // .nonactivatingPanel lets the panel become key without activating
            // Clippable as the frontmost app — that's what previously caused
            // macOS to yank the user to whichever Space the panel lived on.
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        // We manage hide/show manually; avoid auto-hide-on-deactivate
        // since with .nonactivatingPanel the app may never be "active".
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = true
        panel.isReleasedWhenClosed = false
        // Appear on all Spaces (including over fullscreen apps) so the panel
        // follows the user without forcing a Space switch.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
