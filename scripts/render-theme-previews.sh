#!/bin/zsh
set -eu
cd "${0:A:h:h}"
PREVIEW_DIR="${1:-output/theme-previews}"
THEME_ID="${2:-original}"
TASK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/notchbar-theme.XXXXXX")
trap 'rm -rf "$TASK_DIR"' EXIT
cat > "$TASK_DIR/main.swift" <<'SWIFT'
import AppKit
_ = NSApplication.shared
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
let theme = ThemeDesign.originals.first { $0.id == CommandLine.arguments[2] } ?? ThemeDesign.originals[0]
let expandedHeight: CGFloat = theme.material == .paperCut ? 224 : 422
let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: 10, minute: 10))!
for family in VisualFamily.allCases {
 for widgetIndex in [0, 1, 2] {
  let host = ClockContentView(frame: .zero)
  host.barHeight = 32; host.notchGap = 185
  host.select(ClockPack.builtIn.clocks[1])
  host.selectWidget(WidgetDesign.originals[widgetIndex])
  host.visualFamily = family
  host.applyTheme(theme)
  var samples: [UsageProvider: UsageSnapshot] = [:]
  for (i, provider) in UsageProvider.allCases.enumerated() {
   samples[provider] = UsageSnapshot(provider: provider, observedAt: date,
      windows: [UsageWindow(usedPercent: i == 0 ? 42 : 68, durationMinutes: 300, resetsAt: date.addingTimeInterval(7200)),
                UsageWindow(usedPercent: 25, durationMinutes: 10080, resetsAt: date.addingTimeInterval(86400))], bankedResetCount: provider == .codex ? 3 : nil)
  }
  host.applyUsage(samples, status: [:])
  host.update(date: date)
  for step in 0...4 {
   let p = CGFloat(step) / 4
   host.frame = NSRect(x: 0, y: 0, width: mix(409, 640, p), height: mix(32, expandedHeight, p))
   host.setProgress(p)
   host.layoutSubtreeIfNeeded()
   let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
   host.cacheDisplay(in: host.bounds, to: bitmap)
   try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("\(family.rawValue)-\(widgetIndex)-\(step).png"))
  }
 }
}

@MainActor final class PreviewCanvas: NSView {
 override var isFlipped: Bool { true }
 override func draw(_ rect: NSRect) { ThemePalette().shell.setFill(); bounds.fill() }
}
let canvas = PreviewCanvas(frame: NSRect(x: 0, y: 0, width: 640, height: expandedHeight))
let host = ClockContentView(frame: .zero)
host.barHeight = 32; host.notchGap = 185
host.select(ClockPack.builtIn.clocks[1])
host.applyTheme(theme)
host.update(date: date)
canvas.addSubview(host)
var motion = MorphMotion()
for index in 0..<80 {
 motion.target = index >= 10 && index < 50 ? 1 : 0
 motion.advance(by: 1 / 20)
 let p = motion.value
 let width = mix(409, 640, p)
 host.frame = NSRect(x: (640 - width) / 2, y: 0, width: width, height: mix(32, expandedHeight, p))
 host.setProgress(p)
 canvas.layoutSubtreeIfNeeded()
 let bitmap = canvas.bitmapImageRepForCachingDisplay(in: canvas.bounds)!
 canvas.cacheDisplay(in: canvas.bounds, to: bitmap)
 try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(String(format: "motion-%03d.png", index)))
}
SWIFT
sources=(Sources/NotchClock/*.swift)
sources=("${(@)sources:#Sources/NotchClock/main.swift}")
sources=("${(@)sources:#Sources/NotchClock/AppDelegate.swift}")
swiftc -swift-version 6 "${sources[@]}" "$TASK_DIR/main.swift" -o "$TASK_DIR/render"
"$TASK_DIR/render" "$PREVIEW_DIR" "$THEME_ID"
print "Rendered theme families and motion frames in $PREVIEW_DIR"
