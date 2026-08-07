#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Building AthanBar…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/AthanBar"
APP="$ROOT/AthanBar.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

cp "$BIN" "$MACOS/AthanBar"
chmod +x "$MACOS/AthanBar"

# Copy SwiftPM resource bundle if present
BUNDLE_DIR="$(dirname "$BIN")"
if compgen -G "$BUNDLE_DIR/AthanBar_AthanBar.bundle" > /dev/null; then
  cp -R "$BUNDLE_DIR/AthanBar_AthanBar.bundle" "$RES/"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Athan</string>
  <key>CFBundleDisplayName</key>
  <string>Athan</string>
  <key>CFBundleIdentifier</key>
  <string>com.athan.menubar</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>AthanBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSLocationUsageDescription</key>
  <string>Athan uses your location to calculate accurate prayer times.</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Athan uses your location to calculate accurate prayer times.</string>
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>Athan uses your location to calculate accurate prayer times.</string>
</dict>
</plist>
PLIST

echo "Built: $APP"
echo "Launching…"
open "$APP"
