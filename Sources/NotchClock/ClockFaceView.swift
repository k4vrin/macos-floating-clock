import AppKit

@MainActor
final class ClockFaceView: NotchItemView {

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let diameter = min(bounds.width, bounds.height) - 12
        let frame = NSRect(x: (bounds.width - diameter) / 2, y: (bounds.height - diameter) / 2,
                           width: diameter, height: diameter)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let radius = diameter / 2

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -4)
        shadow.set()
        accent.setFill()
        NSBezierPath(ovalIn: frame).fill()
        NSGraphicsContext.restoreGraphicsState()

        let rim = frame.insetBy(dx: 8, dy: 8)
        palette.ink.setFill()
        NSBezierPath(ovalIn: rim).fill()
        let dial = frame.insetBy(dx: 13, dy: 13)
        NSGradient(starting: palette.highlight,
                   ending: palette.surface)?.draw(in: NSBezierPath(ovalIn: dial), angle: 90)
        NSColor.white.withAlphaComponent(0.20).setStroke()
        let edge = NSBezierPath(ovalIn: frame.insetBy(dx: 0.5, dy: 0.5))
        edge.lineWidth = 1
        edge.stroke()

        for index in 0..<12 {
            let angle = CGFloat(index) * .pi / 6
            let position = CGPoint(x: center.x + sin(angle) * radius * 0.76,
                                   y: center.y - cos(angle) * radius * 0.76)
            context.saveGState()
            context.translateBy(x: position.x, y: position.y)
            context.rotate(by: angle)
            let color: NSColor = index % 3 == 0 ? palette.ink :
                (index % 3 == 1 ? NSColor(srgbRed: 0.81, green: 0.43, blue: 0.28, alpha: 1) :
                    NSColor(srgbRed: 0.84, green: 0.66, blue: 0.29, alpha: 1))
            let marker = NSBezierPath(roundedRect: NSRect(x: -5, y: -12, width: 10, height: 24),
                                      xRadius: 5, yRadius: 5)
            NSGraphicsContext.saveGraphicsState()
            let lift = NSShadow()
            lift.shadowColor = palette.ink.withAlphaComponent(0.2)
            lift.shadowBlurRadius = 2
            lift.shadowOffset = NSSize(width: 1, height: -2)
            lift.set()
            color.setFill()
            marker.fill()
            NSGraphicsContext.restoreGraphicsState()
            context.restoreGState()
        }

        drawText("a little out of the ordinary", at: NSRect(x: center.x - 90, y: center.y + radius * 0.46,
                                                         width: 180, height: 14),
                 font: .systemFont(ofSize: diameter * 0.033, weight: .medium), color: palette.ink)
        let angles = HandAngles(date: date, calendar: .current)
        drawWavyHand(center: center, angle: angles.hour, length: radius * 0.49,
                 width: radius * 0.095, color: accent, wave: radius * 0.04)
        drawWavyHand(center: center, angle: angles.minute, length: radius * 0.66,
                 width: radius * 0.073, color: palette.ink, wave: radius * 0.035)

        NSColor(srgbRed: 0.80, green: 0.65, blue: 0.35, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)).fill()
        NSColor.white.withAlphaComponent(0.4).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 4, y: center.y - 4, width: 4, height: 4)).fill()
    }


}

@MainActor
func drawWavyHand(center: CGPoint, angle: Double, length: CGFloat,
                          width: CGFloat, color: NSColor, wave: CGFloat, tail: CGFloat = 7) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle)
        let hand = NSBezierPath()
        hand.move(to: CGPoint(x: 0, y: tail))
        for segment in 0..<4 {
            let start = -length * CGFloat(segment) / 4
            let end = -length * CGFloat(segment + 1) / 4
            let offset = segment % 2 == 0 ? wave : -wave
            hand.curve(to: CGPoint(x: 0, y: end), controlPoint1: CGPoint(x: offset, y: start - length / 12),
                       controlPoint2: CGPoint(x: offset, y: end + length / 12))
        }
        hand.lineWidth = width
        hand.lineCapStyle = .round
        hand.lineJoinStyle = .round
        color.setStroke()
        hand.stroke()
        context.restoreGState()
    }

@MainActor
func drawText(_ text: String, at rect: NSRect, font: NSFont, color: NSColor,
              alignment: NSTextAlignment = .center) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color,
                                                      .paragraphStyle: paragraph])
}
