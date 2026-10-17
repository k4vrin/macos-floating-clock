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
        setAccessibilityLabel("Calendar, " + string("EEEEyMMMMd"))
    }
    override func draw(_ dirtyRect: NSRect) {
        let p = expansionProgress
        let dial = drawThemeHousing(in: bounds.insetBy(dx: mix(0.5, 4, p), dy: mix(0.5, 12, p)),
                                    palette: palette, accent: accent, progress: p, mountOnLeft: true)
        let day = String(Calendar.current.component(.day, from: date))
        let numberHeight = mix(20, min(96, dial.height * 0.42), p)
        let numberWidth = mix(26, dial.width * 0.62, p)
        let number = NSRect(x: dial.midX - numberWidth / 2, y: dial.midY - numberHeight / 2 - 6 * p,
                            width: numberWidth, height: numberHeight)
        drawThemeNumber(day, in: number, family: visualFamily, palette: palette)
        let weekday = mix(NSRect(x: dial.minX + 2, y: dial.midY - 5, width: 27, height: 12),
                          NSRect(x: dial.minX + 10, y: number.minY - 22, width: dial.width - 20, height: 17), p)
        var weekdayFrame = weekday
        weekdayFrame.origin.y = mix(dial.midY - 5, number.minY - 22, min(1, p * 3))
        drawText(string("EEE").uppercased(), at: weekdayFrame,
                 font: .systemFont(ofSize: mix(7, 11, p), weight: .semibold), color: palette.ink)
        let month = mix(NSRect(x: dial.maxX - 29, y: dial.midY - 5, width: 27, height: 12),
                        NSRect(x: dial.minX + 10, y: number.maxY + 16, width: dial.width - 20, height: 20), p)
        var monthFrame = month
        monthFrame.origin.y = mix(dial.midY - 5, number.maxY + 16, min(1, p * 3))
        drawText(string("MMM").uppercased(), at: monthFrame,
                 font: .systemFont(ofSize: mix(7, 13, p), weight: .semibold), color: palette.ink)
        drawText(string("y"), at: NSRect(x: dial.minX, y: monthFrame.maxY + 7, width: dial.width, height: 15),
                 font: .systemFont(ofSize: 10, weight: .medium), color: palette.ink.withAlphaComponent(max(0, (p - 0.7) / 0.3)))
    }
}
