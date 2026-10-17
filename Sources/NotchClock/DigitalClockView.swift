import AppKit

@MainActor
final class DigitalClockView: NotchItemView {
    private let formatter = DateFormatter()

    init(compact: Bool) {
        super.init(frame: .zero)
        expansionProgress = compact ? 0 : 1
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        let p = expansionProgress
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = uses24HourTime ? "HH:mm" : "hh:mm"
        let body = mix(bounds.insetBy(dx: 0.5, dy: 0.5),
                       NSRect(x: 5, y: bounds.height * 0.21, width: bounds.width - 10, height: bounds.height * 0.60), p)
        let dial = drawThemeHousing(in: body, palette: palette, accent: accent, progress: p)
        let area = dial.insetBy(dx: mix(3, 14, p), dy: mix(2, 32, p))
        drawThemeNumber(formatter.string(from: date), in: area, family: visualFamily, palette: palette)
        drawText(palette.isPaperCut ? "PAPER / LOCAL" : (visualFamily == .wavy ? "WAVY / LOCAL" : "COUNTER / LOCAL"),
                 at: NSRect(x: dial.minX, y: dial.minY + 13, width: dial.width, height: 14),
                 font: .systemFont(ofSize: 9, weight: .semibold), color: palette.ink.withAlphaComponent(max(0, (p - 0.65) / 0.35)))
    }
}
