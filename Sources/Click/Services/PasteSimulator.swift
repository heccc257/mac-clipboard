import CoreGraphics
import AppKit

enum PasteSimulator {
    static func simulatePaste() {
        // Check accessibility permission
        guard AXIsProcessTrusted() else {
            promptForAccessibility()
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        // Key down Cmd+V
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else { return }
        keyDown.flags = .maskCommand

        // Key up Cmd+V
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else { return }
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    static func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
