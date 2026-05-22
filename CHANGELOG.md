# Changelog

All notable changes to Clippable are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-05-22

First tagged release. The app has been in daily use; this cut establishes a
baseline so subsequent changes can be tracked semver-style.

### Added
- Menu bar clipboard history manager (no Dock icon, `.accessory` activation)
- Text history panel via `Cmd+Shift+V` or left-click on the menu bar icon
- Image / file list via right-click on the menu bar icon
- "Send to Remote" — push the latest or a chosen image to a VSCode SSH host
  via `scp` to `/tmp/clippable/`
- Global hotkey `Ctrl+Cmd+V` to send the latest image to the remote host
- Persistent history under `~/Library/Application Support/Clippable/`
  (500-item cap, 10MB-per-image cap)
- Click-outside-to-close behavior for the history panel
- Multi-Space / fullscreen visibility for the panel
- `VERSION` file as the single source of truth for the app version,
  consumed by `build-app.sh` to populate `CFBundleVersion` and
  `CFBundleShortVersionString`

### Fixed
- VSCode freeze when pasting from the Clippable panel
- Self-copy loop where items pasted from Clippable were re-recorded
- `Process` + `Pipe` deadlock by routing stdout to temp files

[Unreleased]: https://github.com/Heccc257/Mac-clipboard/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Heccc257/Mac-clipboard/releases/tag/v1.0.0
