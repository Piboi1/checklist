#!/bin/bash
# Builds Checklist.app. No Apple ID needed: the app is signed ad hoc for this Mac only.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=Checklist.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Checklist "$APP/Contents/MacOS/Checklist"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Checklist</string>
    <key>CFBundleIdentifier</key><string>local.checklist</string>
    <key>CFBundleName</key><string>Checklist</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP. Run it with: open $APP"
