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
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            nil
        )

        // Cmd+Shift+V -> toggle clipboard panel (id: 1)
        let toggleID = EventHotKeyID(signature: OSType(0x434C4B00), id: 1)
        RegisterEventHotKey(9, UInt32(cmdKey | shiftKey), toggleID, GetApplicationEventTarget(), 0, &hotKeyRef)
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
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                      nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

    debugLog("hotKeyHandler called! id=\(hotKeyID.id) sig=\(hotKeyID.signature)")

    if hotKeyID.id == 1 {
        NotificationCenter.default.post(name: .toggleClipboardPanel, object: nil)
    }

    return noErr
}
