import AppKit

@MainActor
final class DateWidgetView: WidgetSurfaceView {
    private let formatter = DateFormatter()

    private func string(_ template: String) -> String {
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.calendar = .current
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    override func updateAccessibility() {
        setAccessibilityLabel((compact ? "Expand date, " : "Calendar, ") + string("EEEEyMMMMd"))
    }

    override func draw(_ dirtyRect: NSRect) {
        let card = bounds.insetBy(dx: compact ? 1 : 4, dy: compact ? 1 : 4)
        palette.surface.setFill()
        NSBezierPath(roundedRect: card, xRadius: compact ? 5 : 16, yRadius: compact ? 5 : 16).fill()
        if compact {
            let band = NSRect(x: card.minX, y: card.minY, width: 35, height: card.height)
            accent.setFill()
            NSBezierPath(roundedRect: band, xRadius: 5, yRadius: 5).fill()
            NSRect(x: band.maxX - 5, y: band.minY, width: 5, height: band.height).fill()
            drawText(string("EEE").uppercased(), at: NSRect(x: band.minX, y: card.midY - 6, width: band.width, height: 13),
                     font: .systemFont(ofSize: 8, weight: .bold), color: palette.surface)
            drawText(string("d"), at: NSRect(x: band.maxX + 3, y: card.midY - 10, width: 28, height: 22),
                     font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold), color: palette.ink)
            drawText(string("MMM").uppercased(), at: NSRect(x: band.maxX + 33, y: card.midY - 5, width: 36, height: 12),
                     font: .systemFont(ofSize: 8, weight: .semibold), color: palette.ink)
            return
        }
        let header = NSRect(x: card.minX, y: card.minY, width: card.width, height: 52)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: card, xRadius: 16, yRadius: 16).addClip()
        accent.setFill(); header.fill()
        NSGraphicsContext.restoreGraphicsState()
        drawText(string("EEEE").uppercased(), at: NSRect(x: card.minX + 12, y: 27, width: card.width - 24, height: 16),
                 font: .systemFont(ofSize: 12, weight: .bold), color: palette.surface)
        for x in [card.minX + 35, card.maxX - 35] {
            palette.ink.setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: card.minY - 1, width: 5, height: 14), xRadius: 2.5, yRadius: 2.5).fill()
        }
        drawText(string("d"), at: NSRect(x: card.minX, y: 57, width: card.width, height: 104),
                 font: .monospacedDigitSystemFont(ofSize: 85, weight: .medium), color: palette.ink)
        palette.ink.withAlphaComponent(0.09).setFill()
        NSRect(x: card.minX + 14, y: 110, width: card.width - 28, height: 1).fill()
        drawText(string("yMMMM"), at: NSRect(x: card.minX + 10, y: 161, width: card.width - 20, height: 21),
                 font: .systemFont(ofSize: 16, weight: .medium), color: palette.ink)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        var symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        symbols = Array(symbols[first...] + symbols[..<first])
        let width = (card.width - 24) / 7
        for index in 0..<7 {
            let x = card.minX + 12 + CGFloat(index) * width
            if (index + first) % 7 + 1 == weekday {
                accent.setFill()
                NSBezierPath(ovalIn: NSRect(x: x + (width - 24) / 2, y: 204, width: 24, height: 24)).fill()
            }
            drawText(symbols[index], at: NSRect(x: x, y: 209, width: width, height: 13),
                     font: .systemFont(ofSize: 10, weight: .semibold),
                     color: (index + first) % 7 + 1 == weekday ? palette.surface : palette.ink)
        }
        drawText("TODAY, AT A GLANCE", at: NSRect(x: card.minX, y: card.maxY - 22, width: card.width, height: 11),
                 font: .systemFont(ofSize: 8, weight: .semibold), color: palette.muted)
    }
}
