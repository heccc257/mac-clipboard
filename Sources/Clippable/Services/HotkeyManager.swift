import Carbon
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()

    weak var panelController: ClipboardPanelController?

    private var hotKeyRef: EventHotKeyRef?

    private init() {
        register()
    }

    func register() {
        // Install event handler for hot key events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            nil
        )

        // Register Cmd+Shift+V
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4B00), id: 1)
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 9 // kVK_ANSI_V

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
}

private func hotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    NotificationCenter.default.post(name: .toggleClipboardPanel, object: nil)
    return noErr
}
