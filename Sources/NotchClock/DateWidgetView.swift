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
        let dial = drawThemeHousing(in: housingBody,
                                    palette: palette, accent: accent, progress: p, mountOnLeft: true, sharedFrame: sharesPaperFrame)
        let day = String(Calendar.current.component(.day, from: date))
        let numberHeight = mix(20, min(76, dial.height * 0.42), p)
        let numberWidth = mix(26, dial.width * 0.35, p)
        let number = NSRect(x: dial.midX - numberWidth / 2, y: dial.midY - numberHeight / 2,
                            width: numberWidth, height: numberHeight)
        drawThemeNumber(day, in: number, family: visualFamily, palette: palette)
        let weekday = mix(NSRect(x: dial.minX + 2, y: dial.midY - 5, width: 27, height: 12),
                          NSRect(x: dial.minX + 8, y: dial.midY - 7, width: 58, height: 17), p)
        drawText(string("EEE").uppercased(), at: weekday,
                 font: .systemFont(ofSize: mix(7, 11, p), weight: .semibold), color: palette.isPaperCut ? ThemePalette.color("B64B27") : palette.ink)
        let month = mix(NSRect(x: dial.maxX - 29, y: dial.midY - 5, width: 27, height: 12),
                        NSRect(x: dial.maxX - 66, y: dial.midY - 7, width: 58, height: 20), p)
        drawText(string("MMM").uppercased(), at: month,
                 font: .systemFont(ofSize: mix(7, 13, p), weight: .semibold), color: palette.ink)
        if palette.isPaperCut {
            palette.ink.withAlphaComponent(0.35 * p).setFill()
            for x in [dial.minX + dial.width / 3, dial.minX + dial.width * 2 / 3] {
                NSRect(x: x, y: dial.midY - 24 * p, width: 0.5, height: 48 * p).fill()
            }
        } else {
            drawText(string("y"), at: NSRect(x: dial.minX, y: number.maxY + 7, width: dial.width, height: 15),
                     font: .systemFont(ofSize: 10, weight: .medium), color: palette.ink.withAlphaComponent(max(0, (p - 0.7) / 0.3)))
        }
    }
}
