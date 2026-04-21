# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build              # Compile (debug)
swift build -c release   # Compile (release)
./build-app.sh           # Build .app bundle
cp -r Clippable.app /Applications/  # Install
```

No tests or linter configured yet.

## Architecture

Clippable is a native macOS clipboard history manager (like Windows Win+V), built with Swift Package Manager. It runs as a menu bar accessory app (no Dock icon).

### Two UIs

- **SwiftUI panel** (Cmd+Shift+V or left-click menu bar): text-only clipboard history with search and click-to-paste
- **AppKit NSMenu** (right-click menu bar): recent images/files with "Send to Remote" and "Copy to Clipboard" actions

This split exists because SwiftUI `Button` events are unreliable inside `NSPanel` — `onTapGesture` works but `Button` and nested gestures do not. Text paste uses `onTapGesture` successfully; image send actions use pure AppKit `NSMenu`/`NSMenuItem`.

### Core Flow

1. **main.swift** bootstraps `NSApplication` with `.accessory` activation policy
2. **ClipboardMonitor** polls `NSPasteboard.general.changeCount` every 0.5s, detects text/image/file content, deduplicates via content hash
3. **StatusBarController** manages the menu bar icon; left-click toggles the SwiftUI panel, right-click shows the image/file NSMenu
4. **HotkeyManager** registers two Carbon global hotkeys: Cmd+Shift+V (toggle panel) and Ctrl+Cmd+V (send latest image to remote)
5. **ClipboardPanelController** creates a floating `NSPanel` hosting a SwiftUI view for text history
6. **RemoteManager** detects VSCode SSH connections via `ps` and sends files via `scp` to `/tmp/clippable/` on the remote host
7. **StorageManager** persists history as JSON in `~/Library/Application Support/Clippable/`, images as separate PNG files

### Key Design Decisions

- No external dependencies — system frameworks only (AppKit, SwiftUI, Carbon, CoreGraphics)
- `Process` stdout is written to temp files instead of `Pipe` to avoid `Pipe` + `waitUntilExit` deadlocks
- Self-copy detection: `ClipboardMonitor.isInternalCopy` flag prevents re-recording items pasted from Clippable
- Paste simulation requires **Accessibility permission** (`AXIsProcessTrusted`)
- VSCode SSH connections detected by matching `ssh.*-T.*-D` in `ps -eo command` output
- History capped at 500 items; images capped at 10MB each

### Communication Pattern

Components communicate via `NotificationCenter` with `.toggleClipboardPanel` and `.sendToRemote` notifications, allowing Carbon hotkey handlers (C function pointers) and status bar to trigger actions.
