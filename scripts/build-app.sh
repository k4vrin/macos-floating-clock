#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build -c release
APP="build/Wavy Clock.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/NotchClock "$APP/Contents/MacOS/NotchClock"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>NotchClock</string>
<key>CFBundleIdentifier</key><string>dev.kavrin.notchclock.prototype</string>
<key>CFBundleName</key><string>Wavy Clock</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
print "Built $APP"
