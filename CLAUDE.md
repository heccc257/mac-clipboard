# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build          # Compile (debug)
swift build -c release  # Compile (release)
swift run            # Build and run the app
```

No tests or linter configured yet.

## Architecture

Click is a native macOS clipboard history manager (like Windows Win+V), built with Swift Package Manager. It runs as a menu bar accessory app (no Dock icon).

### Core Flow

1. **main.swift** bootstraps `NSApplication` with `.accessory` activation policy and starts `AppDelegate`
2. **ClipboardMonitor** polls `NSPasteboard.general.changeCount` every 0.5s, detects new content, deduplicates via content hash, and stores `ClipboardItem` entries
3. **StatusBarController** manages the menu bar icon; left-click toggles the panel, right-click shows a context menu
4. **HotkeyManager** registers a global Cmd+Shift+V hotkey via Carbon `RegisterEventHotKey`, posts a `Notification` to toggle the panel
5. **ClipboardPanelController** creates a floating `NSPanel` (non-activating, so it doesn't steal focus) hosting a SwiftUI view
6. **ClipboardHistoryView** shows a searchable list; selecting an item writes it to the pasteboard and **PasteSimulator** fires a `CGEvent` Cmd+V into the frontmost app
7. **StorageManager** persists history as JSON in `~/Library/Application Support/Click/`, images stored as separate PNG files in an `images/` subdirectory

### Key Design Decisions

- No external dependencies — everything uses system frameworks (AppKit, SwiftUI, Carbon, CoreGraphics)
- Self-copy detection: `ClipboardMonitor.isInternalCopy` flag prevents re-recording items pasted from Click itself
- Paste simulation requires **Accessibility permission** (`AXIsProcessTrusted`); the app prompts on first use
- Panel hides when user clicks outside (via `NSEvent.addGlobalMonitorForEvents`) or selects an item
- Debounced saves (2s) avoid disk thrashing during rapid copy sequences
- History capped at 500 items; images capped at 10MB each

### Communication Pattern

Components communicate via `NotificationCenter` with `.toggleClipboardPanel` notification, allowing both the hotkey handler (C function pointer callback) and status bar to trigger the same panel toggle.
