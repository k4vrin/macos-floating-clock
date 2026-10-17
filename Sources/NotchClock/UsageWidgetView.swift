import AppKit

@MainActor
final class UsageWidgetView: WidgetSurfaceView {
    var provider = UsageProvider.codex { didSet { needsDisplay = true; updateAccessibility() } }

    // Match exact windows so missing five-hour data never borrows the weekly percentage.
    var windowRows: [UsageWindow?] {
        [300, 10080].map { duration in
            snapshots[provider]?.windows.first { $0.durationMinutes == duration }
        }
    }

    override func updateAccessibility() {
        let snapshot = snapshots[provider]
        let state = snapshot?.isStale(at: date) == true ? "Stale, refresh needed" :
            (providerStatus[provider] ?? (snapshot == nil ? "Not connected" : "Cached"))
        let windows = zip(["5-hour", "Weekly"], windowRows).map { title, window in
            guard let window else { return "\(title) usage unavailable" }
            guard !window.isExpired(at: date) else { return "\(title) window expired, awaiting data" }
            let reset = window.resetDescription(at: date).map { ", resets in " + $0 } ?? ""
            return "\(title), \(Int(window.usedPercent)) percent used" + reset
        }.joined(separator: ". ")
        let summary = "\(provider.title) subscription usage. \(state). \(windows)"
        setAccessibilityLabel(summary)
        toolTip = summary
    }

    override func draw(_ dirtyRect: NSRect) {
        let p = expansionProgress
        let details = max(0, (p - 0.7) / 0.3)
        let dial = drawThemeHousing(in: housingBody,
                                    palette: palette, accent: accent, progress: p, mountOnLeft: true)
        drawText(provider.title.uppercased(),
                 at: NSRect(x: dial.minX, y: dial.minY + mix(0, 10, p), width: dial.width, height: mix(6, 13, p)),
                 font: .systemFont(ofSize: mix(4.5, 9, p), weight: .semibold), color: palette.ink)
        let snapshot = snapshots[provider]
        for (index, window) in windowRows.enumerated() {
            let valid = window.map { !$0.isExpired(at: date) } ?? false
            let value = valid ? window.map { "\(Int($0.usedPercent))%" } ?? "--" : "--"
            let compactX = dial.minX + CGFloat(index) * dial.width / 2
            let columnX = dial.minX + CGFloat(index) * dial.width / 2
            let number = mix(NSRect(x: compactX + 3, y: dial.midY - 2, width: dial.width / 2 - 6, height: 11),
                             NSRect(x: columnX + 8, y: dial.minY + 57, width: dial.width / 2 - 16, height: 43), p)
            if valid { drawThemeNumber(value, in: number, family: visualFamily, palette: palette) }
            else {
                drawText(value, at: number, font: .systemFont(ofSize: mix(10, 38, p), weight: .medium), color: palette.ink)
            }
            let title = index == 0 ? "5H" : "WEEK"
            let label = mix(NSRect(x: compactX + 2, y: dial.minY + 6, width: dial.width / 2 - 4, height: 6),
                            NSRect(x: columnX + 4, y: dial.minY + 40, width: dial.width / 2 - 8, height: 11), p)
            drawText(title, at: label, font: .systemFont(ofSize: mix(4, 7, p), weight: .semibold), color: palette.ink)
            let track = mix(NSRect(x: compactX + 6, y: dial.maxY - 3, width: dial.width / 2 - 12, height: 1),
                            NSRect(x: columnX + 15, y: dial.minY + 106, width: dial.width / 2 - 30, height: 2), p)
            palette.ink.withAlphaComponent(0.14).setFill()
            NSBezierPath(roundedRect: track, xRadius: 1, yRadius: 1).fill()
            if let window, valid {
                accent.setFill()
                NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY,
                    width: track.width * window.usedPercent / 100, height: track.height), xRadius: 1, yRadius: 1).fill()
            }
            let detail: String
            if let window {
                detail = valid ? window.resetDescription(at: date).map { "Resets in " + $0 } ?? "Reset time unavailable" : "Reset · awaiting data"
            } else { detail = snapshot == nil ? "Not connected" : "Usage unavailable" }
            drawText(detail, at: NSRect(x: columnX + 5, y: dial.minY + 114, width: dial.width / 2 - 10, height: 11),
                     font: .systemFont(ofSize: 7), color: palette.ink.withAlphaComponent(details))
        }
        let status = snapshot?.isStale(at: date) == true ? "STALE · REFRESH NEEDED" : "SUBSCRIPTION LIMITS · USED"
        drawText(status, at: NSRect(x: dial.minX, y: dial.maxY - 17, width: dial.width, height: 9),
                 font: .systemFont(ofSize: 5.5, weight: .medium), color: palette.ink.withAlphaComponent(details))
    }
}
