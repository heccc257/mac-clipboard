# Clippable

A native macOS clipboard history manager, like Windows Win+V. Built with Swift/SwiftUI/AppKit.

Current version: see [`VERSION`](VERSION). Release notes: [`CHANGELOG.md`](CHANGELOG.md).

To cut a release: bump `VERSION`, move entries from `## [Unreleased]` into a new `## [X.Y.Z]` section in `CHANGELOG.md`, run `./build-app.sh`, then tag as `vX.Y.Z`.

## Features

- **Clipboard History**: Monitors and records text, images, and file copies
- **Quick Paste**: Press `Cmd+Shift+V` to open the text history panel, click to paste
- **Send to Remote**: Right-click the menu bar icon to see recent images/files, send them to a remote host via SCP
- **VSCode SSH Integration**: Automatically detects active VSCode SSH connections
- **Global Hotkeys**:
  - `Cmd+Shift+V` — Open/close text clipboard panel
  - `Ctrl+Cmd+V` — Send latest image to remote host
- **Persistent History**: Survives app restarts, stored in `~/Library/Application Support/Clippable/`

## Install

```bash
git clone git@github.com:Heccc257/Mac-clipboard.git
cd Mac-clipboard
./build-app.sh
cp -r Clippable.app /Applications/
```

Then open Clippable from Applications or Launchpad.

## Usage

| Action | How |
|--------|-----|
| Open text history | `Cmd+Shift+V` or left-click menu bar icon |
| Paste from history | Click any item in the panel |
| View images/files | Right-click menu bar icon |
| Send image to remote | Right-click menu bar icon → hover item → "Send to Remote" |
| Quick send latest image | `Ctrl+Cmd+V` |

## Permissions

- **Accessibility**: Required for paste simulation (`System Settings → Privacy & Security → Accessibility`)
- Re-grant after each reinstall (macOS revokes when binary changes)

## Requirements

- macOS 13.0+ (Ventura)
- Swift 5.9+
- SSH key configured for remote hosts (for Send to Remote feature)
