import AppKit

/// The digital face shares the compact mounting silhouette and the analog clock's cream/red materials.
@MainActor
final class DigitalClockView: NotchItemView {
    private let compact: Bool
    private let formatter = DateFormatter()

    init(compact: Bool) {
        self.compact = compact
        super.init(frame: .zero)
        formatter.dateFormat = "HHmm"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = uses24HourTime ? "HHmm" : "hhmm"
        let digits = formatter.string(from: date)
        let body = compact ? bounds.insetBy(dx: 0.5, dy: 0.5) : NSRect(x: 5, y: 61, width: bounds.width - 10, height: 174)
        let mount: CGFloat = compact ? body.height * 0.65 : 28
        let face = NSRect(x: body.minX, y: body.minY, width: body.width - mount, height: body.height)
        accent.setFill()
        NSBezierPath(roundedRect: face, xRadius: face.height / 2, yRadius: face.height / 2).fill()
        NSRect(x: face.midX, y: body.minY, width: body.maxX - face.midX, height: body.height).fill()
        palette.ink.withAlphaComponent(0.4).setFill()
        NSRect(x: body.maxX - mount * 0.5, y: body.minY, width: compact ? 0.6 : 1, height: body.height).fill()
        let bezel = face.insetBy(dx: compact ? 1.5 : 7, dy: compact ? 1.5 : 7)
        palette.ink.setFill()
        NSBezierPath(roundedRect: bezel, xRadius: bezel.height / 2, yRadius: bezel.height / 2).fill()
        let dial = bezel.insetBy(dx: compact ? 0.8 : 3, dy: compact ? 0.8 : 3)
        NSGradient(starting: palette.highlight, ending: palette.surface)?
            .draw(in: NSBezierPath(roundedRect: dial, xRadius: dial.height / 2, yRadius: dial.height / 2), angle: 90)
        if visualFamily == .wavy {
            let text = String(digits.prefix(2)) + ":" + String(digits.suffix(2))
            drawWavyNumerals(text, in: dial.insetBy(dx: compact ? 4 : 14, dy: compact ? 2 : 32), color: palette.ink)
            if !compact {
                drawText("WAVY / LOCAL", at: NSRect(x: dial.minX + 18, y: dial.minY + 16, width: dial.width - 36, height: 14),
                         font: .systemFont(ofSize: 9, weight: .semibold), color: palette.ink)
            }
            return
        }
        let area = dial.insetBy(dx: compact ? 6 : 16, dy: compact ? 3 : 37)
        let cell = area.width / 4.6
        for (index, digit) in digits.enumerated() {
            let x = area.minX + CGFloat(index) * cell + (index >= 2 ? cell * 0.6 : 0)
            let tile = NSRect(x: x, y: area.minY, width: cell - (compact ? 0.8 : 3), height: area.height)
            palette.ink.setFill()
            NSBezierPath(roundedRect: tile, xRadius: compact ? 1.4 : 5, yRadius: compact ? 1.4 : 5).fill()
            let font = NSFont.monospacedDigitSystemFont(ofSize: area.height * 0.80, weight: .medium)
            let textHeight = font.ascender - font.descender
            drawText(String(digit), at: NSRect(x: tile.minX, y: tile.midY - textHeight / 2,
                                               width: tile.width, height: textHeight + 2), font: font, color: palette.surface)
            palette.surface.withAlphaComponent(0.13).setFill()
            NSRect(x: tile.minX, y: tile.midY, width: tile.width, height: compact ? 0.4 : 1).fill()
        }
        accent.setFill()
        let dot: CGFloat = compact ? 1.1 : 3
        for dy in [-area.height * 0.15, area.height * 0.15] {
            NSBezierPath(ovalIn: NSRect(x: area.minX + cell * 2.1, y: area.midY + dy - dot / 2, width: dot, height: dot)).fill()
        }
        if !compact {
            drawText("DIGITAL / LOCAL", at: NSRect(x: dial.minX + 18, y: dial.minY + 16, width: dial.width - 36, height: 14),
                     font: .systemFont(ofSize: 9, weight: .semibold), color: palette.ink)
            drawText("a little out of the ordinary", at: NSRect(x: dial.minX + 15, y: dial.maxY - 29, width: dial.width - 30, height: 13),
                     font: .systemFont(ofSize: 8), color: palette.ink)
        }
    }
}
