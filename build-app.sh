#!/bin/bash
set -e

echo "Building Click (release)..."
swift build -c release

APP_NAME="Click"
APP_DIR="$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp .build/release/Click "$MACOS/Click"

cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Click</string>
    <key>CFBundleDisplayName</key>
    <string>Click</string>
    <key>CFBundleIdentifier</key>
    <string>com.click.clipboard</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Click</string>
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

echo "✓ Built $APP_DIR"
echo ""
echo "To install:"
echo "  cp -r Click.app /Applications/"
echo ""
echo "Then double-click Click.app in /Applications to run."
echo "It will appear in the menu bar (no Dock icon)."
