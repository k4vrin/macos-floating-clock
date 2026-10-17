import AppKit

/// A horizontal dial with a square mounting end, adapted from the owner's compact-form reference.
@MainActor
final class CompactClockView: NotchItemView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Expand Wavy Clock")
        toolTip = "Expand Wavy Clock"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let p = expansionProgress
        let housing = bounds.insetBy(dx: mix(0.5, 6, p), dy: mix(0.5, 6, p))
        guard housing.height > 4 else { return }
        let mountWidth = housing.height * 0.65 * (1 - p)
        let faceFrame = NSRect(x: housing.minX, y: housing.minY,
                               width: housing.width - mountWidth, height: housing.height)
        let mountingEnd = NSRect(x: faceFrame.maxX - faceFrame.height / 2, y: housing.minY,
                                width: mountWidth + faceFrame.height / 2, height: housing.height)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: housing, xRadius: housing.height / 2 * p,
                     yRadius: housing.height / 2 * p).addClip()
        accent.setFill()
        NSBezierPath(roundedRect: faceFrame, xRadius: faceFrame.height / 2,
                     yRadius: faceFrame.height / 2).fill()
        mountingEnd.fill()
        NSGraphicsContext.restoreGraphicsState()

        palette.ink.withAlphaComponent(0.38).setFill()
        NSRect(x: faceFrame.maxX + mountWidth * 0.38, y: housing.minY,
               width: 0.6 * (1 - p), height: housing.height).fill()
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSRect(x: faceFrame.maxX + mountWidth * 0.38 + 0.6, y: housing.minY,
               width: 0.5 * (1 - p), height: housing.height).fill()

        let bezel = faceFrame.insetBy(dx: mix(1.5, 8, p), dy: mix(1.5, 8, p))
        palette.ink.setFill()
        NSBezierPath(roundedRect: bezel, xRadius: bezel.height / 2, yRadius: bezel.height / 2).fill()
        let dial = bezel.insetBy(dx: mix(0.7, 5, p), dy: mix(0.7, 5, p))
        let dialPath = NSBezierPath(roundedRect: dial, xRadius: dial.height / 2, yRadius: dial.height / 2)
        NSGradient(starting: palette.highlight,
                   ending: palette.surface)?.draw(in: dialPath, angle: 90)

        context.saveGState()
        dialPath.addClip()
        let center = CGPoint(x: dial.midX, y: dial.midY)
        let rx = dial.width / 2 - mix(3, 20, p)
        let ry = dial.height / 2 - mix(2, 20, p)
        for index in 0..<12 {
            let angle = CGFloat(index) * .pi / 6
            let x = center.x + sin(angle) * rx
            let y = center.y - cos(angle) * ry
            let color: NSColor = index % 3 == 0 ? palette.ink :
                (index % 3 == 1 ? NSColor(srgbRed: 0.81, green: 0.43, blue: 0.28, alpha: 1) :
                    NSColor(srgbRed: 0.84, green: 0.66, blue: 0.29, alpha: 1))
            color.setFill()
            let vertical = index == 0 || index == 6
            let width: CGFloat = mix(vertical ? 1.2 : 1.8, 10, p)
            let height: CGFloat = mix(vertical ? 2.2 : 1.2, 24, p)
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: angle * p)
            NSBezierPath(roundedRect: NSRect(x: -width / 2, y: -height / 2,
                                            width: width, height: height), xRadius: mix(0.6, 5, p), yRadius: mix(0.6, 5, p)).fill()
            context.restoreGState()
        }

        let angles = HandAngles(date: date, calendar: .current)
        // A radial intersection keeps each hand inside the elongated dial at every angle.
        func reach(_ angle: Double, fraction: CGFloat) -> CGFloat {
            let sine = CGFloat(sin(angle))
            let cosine = CGFloat(cos(angle))
            return fraction / sqrt(sine * sine / (rx * rx) + cosine * cosine / (ry * ry))
        }
        drawWavyHand(center: center, angle: angles.hour, length: reach(angles.hour, fraction: 0.6),
                     width: mix(1.7, 13, p), color: accent, wave: mix(0.8, 5.6, p), tail: mix(0.8, 7, p))
        drawWavyHand(center: center, angle: angles.minute, length: reach(angles.minute, fraction: 0.8),
                     width: mix(1.35, 10, p), color: palette.ink, wave: mix(0.65, 4.9, p), tail: mix(0.8, 7, p))
        NSColor(srgbRed: 0.80, green: 0.65, blue: 0.35, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - mix(1.2, 7, p), y: center.y - mix(1.2, 7, p), width: mix(2.4, 14, p), height: mix(2.4, 14, p))).fill()
        context.restoreGState()
    }

}
