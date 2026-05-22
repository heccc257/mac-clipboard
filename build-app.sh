#!/bin/bash
set -e

VERSION=$(cat VERSION | tr -d '[:space:]')
echo "Building Clippable v$VERSION (release)..."
swift build -c release

APP_NAME="Clippable"
APP_DIR="$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp .build/release/Clippable "$MACOS/Clippable"

cat > "$CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Clippable</string>
    <key>CFBundleDisplayName</key>
    <string>Clippable</string>
    <key>CFBundleIdentifier</key>
    <string>com.clippable.clipboard</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>Clippable</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "✓ Built $APP_DIR (v$VERSION)"
echo ""
echo "To install:"
echo "  cp -r Clippable.app /Applications/"
echo ""
echo "Then double-click Clippable.app in /Applications to run."
echo "It will appear in the menu bar (no Dock icon)."
