#!/bin/zsh
set -eu
cd "${0:A:h:h}"
PREVIEW_DIR="${1:-output}"
TASK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/notchbar-numerals.XXXXXX")
trap 'rm -rf "$TASK_DIR"' EXIT
cat > "$TASK_DIR/main.swift" <<'SWIFT'
import AppKit

@MainActor
final class NumeralSheet: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(srgbRed: 0.94, green: 0.9, blue: 0.77, alpha: 1).setFill()
        bounds.fill()
        drawText("WAVY / VECTOR NUMERALS", at: NSRect(x: 24, y: 14, width: 710, height: 22),
                 font: .systemFont(ofSize: 14, weight: .semibold), color: .darkGray, alignment: .left)
        for (index, digit) in "0123456789".enumerated() {
            drawWavyNumerals(String(digit), in: CGRect(x: 24 + CGFloat(index) * 70, y: 46, width: 58, height: 91),
                             color: ThemePalette().ink)
        }
        drawWavyNumerals("11:11", in: CGRect(x: 24, y: 158, width: 160, height: 58), color: ThemePalette().clockAccent)
        drawWavyNumerals("08:08", in: CGRect(x: 270, y: 158, width: 160, height: 58), color: ThemePalette().ink)
        drawWavyNumerals("100%", in: CGRect(x: 515, y: 158, width: 160, height: 58), color: ThemePalette().ink)
    }
}
@MainActor
func save(_ view: NSView, name: String) throws {
    view.layoutSubtreeIfNeeded()
    guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("No bitmap") }
    view.cacheDisplay(in: view.bounds, to: bitmap)
    try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent(name))
}
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
_ = NSApplication.shared
try save(NumeralSheet(frame: NSRect(x: 0, y: 0, width: 750, height: 240)), name: "wavy-numeral-sheet.png")
for family in VisualFamily.allCases {
    for compact in [false, true] {
        let view = DigitalClockView(compact: compact)
        view.visualFamily = family
        view.frame = NSRect(x: 0, y: 0, width: compact ? 84 : 292, height: compact ? 32 : 292)
        view.date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 8, minute: 8))!
        try save(view, name: "\(family.rawValue)-digital-\(compact ? "compact" : "expanded").png")
    }
}
SWIFT
sources=(Sources/NotchClock/*.swift)
sources=("${(@)sources:#Sources/NotchClock/main.swift}")
sources=("${(@)sources:#Sources/NotchClock/AppDelegate.swift}")
swiftc -swift-version 6 "${sources[@]}" "$TASK_DIR/main.swift" -o "$TASK_DIR/render"
"$TASK_DIR/render" "$PREVIEW_DIR"
print "Rendered Wavy/Counter previews in $PREVIEW_DIR"
