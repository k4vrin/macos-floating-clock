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
        if compact {
            for (index, provider) in UsageProvider.allCases.enumerated() {
                let x = CGFloat(index) * 54 + 1
                let window = usable(provider)
                ring(in: NSRect(x: x, y: bounds.midY - 7, width: 14, height: 14), used: window?.usedPercent, color: provider == .codex ? accent : palette.clockAccent, line: 2)
                let stale = snapshots[provider]?.isStale(at: date) == true
                let value = window.map { "\(Int($0.usedPercent))%" + (stale ? "*" : "") } ?? "--"
                drawText((provider == .codex ? "Cx " : "Cl ") + value,
                         at: NSRect(x: x + 17, y: bounds.midY - 5, width: 36, height: 11),
                         font: .monospacedDigitSystemFont(ofSize: 8, weight: .medium), color: palette.text, alignment: .left)
            }
            return
        }
        drawText(displayName.uppercased(), at: NSRect(x: 4, y: 1, width: bounds.width - 8, height: 15),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: palette.muted, alignment: .left)
        for (index, provider) in UsageProvider.allCases.enumerated() {
            drawProvider(provider, frame: NSRect(x: 2, y: 28 + CGFloat(index) * 111, width: bounds.width - 4, height: 102))
        }
        drawText("USED / SUBSCRIPTION LIMITS", at: NSRect(x: 4, y: bounds.height - 14, width: bounds.width - 8, height: 12),
                 font: .systemFont(ofSize: 8, weight: .medium), color: palette.muted, alignment: .left)
    }

    private func drawProvider(_ provider: UsageProvider, frame: NSRect) {
        (palette.shell.blended(withFraction: 0.08, of: palette.text) ?? palette.shell).setFill()
        NSBezierPath(roundedRect: frame, xRadius: 12, yRadius: 12).fill()
        let color: NSColor = provider == .codex ? accent : palette.clockAccent
        let snapshot = snapshots[provider]
        let window = usable(provider)
        let circle = NSRect(x: frame.minX + 12, y: frame.minY + 16, width: 44, height: 44)
        ring(in: circle, used: window?.usedPercent, color: color, line: 4)
        drawText(window.map { "\(Int($0.usedPercent))%" } ?? "--", at: NSRect(x: circle.minX, y: circle.midY - 7, width: 44, height: 17),
                 font: .monospacedDigitSystemFont(ofSize: 12, weight: .medium), color: palette.text)
        drawText(provider.title, at: NSRect(x: frame.minX + 69, y: frame.minY + 10, width: 160, height: 20),
                 font: .systemFont(ofSize: 15, weight: .semibold), color: palette.text, alignment: .left)
        let status: String
        if let snapshot {
            status = snapshot.isStale(at: date) ? "STALE · REFRESH NEEDED" : (providerStatus[provider] ?? "CACHED")
        } else { status = providerStatus[provider] ?? (provider == .claude ? "CONNECT STATUS LINE" : "CONNECT CODEX CLI") }
        drawText(status.uppercased(), at: NSRect(x: frame.minX + 12, y: frame.maxY - 18, width: frame.width - 24, height: 11),
                 font: .systemFont(ofSize: 7, weight: .medium), color: palette.muted, alignment: .left)
        for row in 0..<2 {
            let window = snapshot?.displayWindows[row] ?? nil
            let y = frame.minY + 36 + CGFloat(row) * 20
            let valid = window.map { !$0.isExpired(at: date) } ?? false
            let duration = window?.shortLabel ?? (row == 0 ? "5h" : "7d")
            let text = window.map { item in
                guard valid else { return "\(duration)  reset · awaiting data" }
                let reset = item.resetDescription(at: date).map { " · " + $0 } ?? ""
                return "\(duration)  \(Int(item.usedPercent))% used" + reset
            } ?? "\(duration)  unavailable"
            drawText(text, at: NSRect(x: frame.minX + 69, y: y - 3, width: 160, height: 12),
                     font: .monospacedDigitSystemFont(ofSize: 8, weight: .medium), color: palette.text, alignment: .left)
            let track = NSRect(x: frame.minX + 69, y: y + 10, width: frame.width - 84, height: 3)
            NSColor.white.withAlphaComponent(0.10).setFill()
            NSBezierPath(roundedRect: track, xRadius: 1.5, yRadius: 1.5).fill()
            if let window, valid {
                color.setFill()
                NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY, width: track.width * window.usedPercent / 100, height: 3), xRadius: 1.5, yRadius: 1.5).fill()
            }
        }
    }

    private func ring(in rect: NSRect, used: Double?, color: NSColor, line: CGFloat) {
        let track = NSBezierPath(ovalIn: rect.insetBy(dx: line / 2, dy: line / 2))
        track.lineWidth = line
        NSColor.white.withAlphaComponent(0.12).setStroke(); track.stroke()
        guard let used, used > 0 else { return }
        let arc = NSBezierPath()
        arc.appendArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: (rect.width - line) / 2,
                      startAngle: -90, endAngle: -90 + CGFloat(used) * 3.6, clockwise: false)
        arc.lineWidth = line
        arc.lineCapStyle = .round
        color.setStroke(); arc.stroke()
    }
}
