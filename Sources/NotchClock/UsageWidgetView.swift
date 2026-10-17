import AppKit

@MainActor
final class UsageWidgetView: WidgetSurfaceView {
    private func usable(_ provider: UsageProvider) -> UsageWindow? {
        snapshots[provider]?.windows.first(where: { !$0.isExpired(at: date) })
    }

    override func updateAccessibility() {
        let labels = UsageProvider.allCases.map { provider in
            let snapshot = snapshots[provider]
            let state = snapshot?.isStale(at: date) == true ? "Stale, refresh needed" :
                (providerStatus[provider] ?? (snapshot == nil ? "Not connected" : "Cached"))
            let windows = snapshot?.windows.map { window in
                if window.isExpired(at: date) { return "\(window.shortLabel) window expired, awaiting data" }
                let reset = window.resetDescription(at: date).map { ", resets in " + $0 } ?? ""
                return "\(window.shortLabel) window, \(Int(window.usedPercent)) percent used" + reset
            }.joined(separator: ", ") ?? "Usage unavailable"
            return "\(provider.title), \(state), \(windows)"
        }
        let summary = labels.joined(separator: ". ")
        setAccessibilityLabel((compact ? "Expand AI usage. " : "AI subscription usage. ") + summary)
        toolTip = summary
    }

    override func draw(_ dirtyRect: NSRect) {
        let p = expansionProgress
        let dial = drawThemeHousing(in: bounds.insetBy(dx: mix(0.5, 4, p), dy: mix(0.5, 12, p)),
                                    palette: palette, accent: accent, progress: p, mountOnLeft: true)
        for (index, provider) in UsageProvider.allCases.enumerated() {
            let value = usable(provider).map { "\(Int($0.usedPercent))%" } ?? "--"
            let compactX = dial.minX + CGFloat(index) * dial.width / 2
            let y = dial.minY + 32 + CGFloat(index) * 96
            let number = mix(NSRect(x: compactX + 4, y: dial.midY - 4, width: dial.width / 2 - 8, height: 11),
                             NSRect(x: dial.minX + 70, y: y, width: dial.width - 86, height: 35), p)
            if value == "--" {
                drawText(value, at: number, font: .systemFont(ofSize: mix(9, 26, p)), color: palette.ink)
            } else { drawThemeNumber(value, in: number, family: visualFamily, palette: palette) }
            let label = mix(NSRect(x: compactX + 2, y: dial.minY + 2, width: dial.width / 2 - 4, height: 8),
                            NSRect(x: dial.minX + 14, y: y + 10, width: 52, height: 15), p)
            drawText(provider == .codex ? "CODEX" : "CLAUDE", at: label,
                     font: .systemFont(ofSize: mix(4.5, 9, p), weight: .semibold), color: palette.ink)
            let track = mix(NSRect(x: compactX + 6, y: dial.maxY - 4, width: dial.width / 2 - 12, height: 1),
                            NSRect(x: dial.minX + 16, y: y + 47, width: dial.width - 32, height: 4), p)
            palette.ink.withAlphaComponent(0.14).setFill()
            NSBezierPath(roundedRect: track, xRadius: 2, yRadius: 2).fill()
            if let used = usable(provider)?.usedPercent {
                accent.setFill()
                NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY,
                    width: track.width * used / 100, height: track.height), xRadius: 2, yRadius: 2).fill()
            }
            let snapshot = snapshots[provider]
            let state = snapshot?.isStale(at: date) == true ? "STALE · REFRESH NEEDED" :
                (snapshot == nil ? "NOT CONNECTED" : usable(provider).map { $0.shortLabel + " USED" + ($0.resetDescription(at: date).map { " · RESET " + $0 } ?? "") } ?? "AWAITING DATA")
            drawText(state, at: NSRect(x: dial.minX + 14, y: y + 59, width: dial.width - 28, height: 12),
                     font: .systemFont(ofSize: 7, weight: .medium), color: palette.ink.withAlphaComponent(max(0, (p - 0.7) / 0.3)))
            if let second = snapshot?.displayWindows[1] {
                let detail = second.isExpired(at: date) ? "\(second.shortLabel) RESET · AWAITING DATA" :
                    "\(second.shortLabel) · \(Int(second.usedPercent))% USED" +
                    (second.resetDescription(at: date).map { " · " + $0 } ?? "")
                drawText(detail, at: NSRect(x: dial.minX + 14, y: y + 73, width: dial.width - 28, height: 12),
                         font: .systemFont(ofSize: 7), color: palette.ink.withAlphaComponent(max(0, (p - 0.7) / 0.3)))
            }
        }
    }
}
