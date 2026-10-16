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
        let housing = bounds.insetBy(dx: 0.5, dy: 0.5)
        guard housing.height > 4 else { return }
        let mountWidth = housing.height * 0.65
        let faceFrame = NSRect(x: housing.minX, y: housing.minY,
                               width: housing.width - mountWidth, height: housing.height)
        let mountingEnd = NSRect(x: faceFrame.maxX - faceFrame.height / 2, y: housing.minY,
                                width: mountWidth + faceFrame.height / 2, height: housing.height)
        accent.setFill()
        NSBezierPath(roundedRect: faceFrame, xRadius: faceFrame.height / 2,
                     yRadius: faceFrame.height / 2).fill()
        mountingEnd.fill()

        palette.ink.withAlphaComponent(0.38).setFill()
        NSRect(x: faceFrame.maxX + mountWidth * 0.38, y: housing.minY,
               width: 0.6, height: housing.height).fill()
        NSColor.white.withAlphaComponent(0.18).setFill()
        NSRect(x: faceFrame.maxX + mountWidth * 0.38 + 0.6, y: housing.minY,
               width: 0.5, height: housing.height).fill()

        let bezel = faceFrame.insetBy(dx: 1.5, dy: 1.5)
        palette.ink.setFill()
        NSBezierPath(roundedRect: bezel, xRadius: bezel.height / 2, yRadius: bezel.height / 2).fill()
        let dial = bezel.insetBy(dx: 0.7, dy: 0.7)
        let dialPath = NSBezierPath(roundedRect: dial, xRadius: dial.height / 2, yRadius: dial.height / 2)
        NSGradient(starting: palette.highlight,
                   ending: palette.surface)?.draw(in: dialPath, angle: 90)

        context.saveGState()
        dialPath.addClip()
        let center = CGPoint(x: dial.midX, y: dial.midY)
        let rx = dial.width / 2 - 3
        let ry = dial.height / 2 - 2
        for index in 0..<12 {
            let angle = CGFloat(index) * .pi / 6
            let x = center.x + sin(angle) * rx
            let y = center.y - cos(angle) * ry
            let color: NSColor = index % 3 == 0 ? palette.ink :
                (index % 3 == 1 ? NSColor(srgbRed: 0.81, green: 0.43, blue: 0.28, alpha: 1) :
                    NSColor(srgbRed: 0.84, green: 0.66, blue: 0.29, alpha: 1))
            color.setFill()
            let vertical = index == 0 || index == 6
            let width: CGFloat = vertical ? 1.2 : 1.8
            let height: CGFloat = vertical ? 2.2 : 1.2
            NSBezierPath(roundedRect: NSRect(x: x - width / 2, y: y - height / 2,
                                            width: width, height: height), xRadius: 0.6, yRadius: 0.6).fill()
        }

        let angles = HandAngles(date: date, calendar: .current)
        // A radial intersection keeps each hand inside the elongated dial at every angle.
        func reach(_ angle: Double, fraction: CGFloat) -> CGFloat {
            let sine = CGFloat(sin(angle))
            let cosine = CGFloat(cos(angle))
            return fraction / sqrt(sine * sine / (rx * rx) + cosine * cosine / (ry * ry))
        }
        drawWavyHand(center: center, angle: angles.hour, length: reach(angles.hour, fraction: 0.6),
                     width: 1.7, color: accent, wave: 0.8, tail: 0.8)
        drawWavyHand(center: center, angle: angles.minute, length: reach(angles.minute, fraction: 0.8),
                     width: 1.35, color: palette.ink, wave: 0.65, tail: 0.8)
        NSColor(srgbRed: 0.80, green: 0.65, blue: 0.35, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - 1.2, y: center.y - 1.2, width: 2.4, height: 2.4)).fill()
        context.restoreGState()
    }

}
