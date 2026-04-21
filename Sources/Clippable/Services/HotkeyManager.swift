import Carbon
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()

    weak var panelController: ClipboardPanelController?

    private var hotKeyRef: EventHotKeyRef?
    private var sendHotKeyRef: EventHotKeyRef?

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

        // Ctrl+Cmd+V -> send latest image to remote (id: 2)
        let sendID = EventHotKeyID(signature: OSType(0x434C4B00), id: 2)
        let r = RegisterEventHotKey(9, UInt32(cmdKey | controlKey), sendID, GetApplicationEventTarget(), 0, &sendHotKeyRef)
        debugLog("RegisterEventHotKey Ctrl+Cmd+V result: \(r)")
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = sendHotKeyRef {
            UnregisterEventHotKey(ref)
            sendHotKeyRef = nil
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

    switch hotKeyID.id {
    case 1:
        NotificationCenter.default.post(name: .toggleClipboardPanel, object: nil)
    case 2:
        NotificationCenter.default.post(name: .sendToRemote, object: nil)
    default:
        break
    }

    return noErr
}
