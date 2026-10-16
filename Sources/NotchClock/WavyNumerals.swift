import AppKit

struct WavyGlyphPlacement: Equatable {
    let character: Character
    let frame: CGRect
}

/// Normalized vector strokes keep the same numeral identity in both clock sizes.
enum WavyNumerals {
    static func path(for character: Character) -> CGPath? {
        let path = CGMutablePath()
        func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
        func curve(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ x: CGFloat, _ y: CGFloat) {
            path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x1, y: y1), control2: CGPoint(x: x2, y: y2))
        }
        func line(_ x: CGFloat, _ y: CGFloat) { path.addLine(to: CGPoint(x: x, y: y)) }
        switch character {
        case "0":
            move(0.5, 0.1)
            curve(0.08, 0.04, 0.22, 0.38, 0.15, 0.53)
            curve(0.06, 0.78, 0.3, 0.94, 0.53, 0.9)
            curve(0.96, 0.97, 0.77, 0.63, 0.86, 0.46)
            curve(0.94, 0.21, 0.78, 0.06, 0.5, 0.1)
        case "1":
            move(0.24, 0.27); curve(0.37, 0.26, 0.36, 0.12, 0.54, 0.1)
            curve(0.72, 0.35, 0.37, 0.45, 0.56, 0.63)
            curve(0.68, 0.76, 0.52, 0.79, 0.56, 0.9)
            move(0.28, 0.9); curve(0.47, 0.85, 0.63, 0.95, 0.79, 0.9)
        case "2":
            move(0.15, 0.29); curve(0.12, 0.03, 0.82, 0.01, 0.86, 0.28)
            curve(0.92, 0.5, 0.25, 0.53, 0.15, 0.86)
            curve(0.36, 0.98, 0.64, 0.81, 0.86, 0.9)
        case "3":
            move(0.17, 0.16); curve(0.5, 0.02, 0.92, 0.1, 0.8, 0.34)
            curve(0.72, 0.48, 0.43, 0.43, 0.4, 0.49)
            curve(0.48, 0.55, 0.83, 0.45, 0.86, 0.68)
            curve(0.91, 0.93, 0.43, 0.99, 0.14, 0.83)
        case "4":
            move(0.57, 0.11); curve(0.44, 0.29, 0.14, 0.39, 0.15, 0.59)
            curve(0.37, 0.66, 0.65, 0.51, 0.88, 0.59)
            move(0.72, 0.12); curve(0.88, 0.36, 0.57, 0.48, 0.73, 0.66)
            curve(0.82, 0.77, 0.68, 0.83, 0.73, 0.9)
        case "5":
            move(0.85, 0.12); curve(0.64, 0.05, 0.43, 0.18, 0.23, 0.12)
            line(0.18, 0.47); curve(0.43, 0.36, 0.85, 0.41, 0.86, 0.65)
            curve(0.91, 0.95, 0.4, 1, 0.15, 0.82)
        case "6":
            move(0.78, 0.12); curve(0.41, 0.05, 0.11, 0.4, 0.16, 0.68)
            curve(0.17, 0.98, 0.87, 1, 0.86, 0.66)
            curve(0.86, 0.39, 0.34, 0.42, 0.16, 0.62)
        case "7":
            move(0.14, 0.13); curve(0.34, 0.05, 0.64, 0.21, 0.86, 0.12)
            curve(0.84, 0.37, 0.43, 0.4, 0.54, 0.61)
            curve(0.63, 0.74, 0.37, 0.77, 0.39, 0.9)
        case "8":
            move(0.48, 0.48); curve(0.1, 0.35, 0.16, 0.09, 0.5, 0.1)
            curve(0.86, 0.06, 0.91, 0.38, 0.48, 0.48)
            curve(0.06, 0.55, 0.06, 0.95, 0.51, 0.9)
            curve(0.97, 0.97, 0.97, 0.56, 0.48, 0.48)
        case "9":
            move(0.21, 0.87); curve(0.56, 0.97, 0.89, 0.6, 0.85, 0.33)
            curve(0.85, 0.03, 0.15, 0, 0.15, 0.32)
            curve(0.13, 0.62, 0.66, 0.58, 0.85, 0.37)
        case ":":
            path.addEllipse(in: CGRect(x: 0.25, y: 0.29, width: 0.5, height: 0.09))
            path.addEllipse(in: CGRect(x: 0.25, y: 0.64, width: 0.5, height: 0.09))
        case "%":
            path.addEllipse(in: CGRect(x: 0.12, y: 0.1, width: 0.3, height: 0.27))
            move(0.8, 0.12); curve(0.85, 0.4, 0.18, 0.61, 0.2, 0.88)
            path.addEllipse(in: CGRect(x: 0.58, y: 0.63, width: 0.3, height: 0.27))
        default: return nil
        }
        return path
    }

    static func layout(_ text: String, in rect: CGRect) -> [WavyGlyphPlacement] {
        guard !text.isEmpty, rect.width > 0, rect.height > 0, rect.width.isFinite, rect.height.isFinite,
              text.allSatisfy({ $0.isASCII && ("0123456789:%".contains($0)) }) else { return [] }
        let widths: [CGFloat] = text.map { $0 == ":" ? 0.24 : $0 == "%" ? 0.82 : 0.64 }
        let advance = widths.reduce(0, +)
        let height = min(rect.height, rect.width / advance)
        var x = rect.midX - advance * height / 2
        return zip(text, widths).map { character, width in
            defer { x += width * height }
            return WavyGlyphPlacement(character: character,
                frame: CGRect(x: x, y: rect.midY - height / 2, width: width * height, height: height))
        }
    }
}

@MainActor
func drawWavyNumerals(_ text: String, in rect: CGRect, color: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    defer { context.restoreGState() }
    context.setStrokeColor(color.cgColor)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    for glyph in WavyNumerals.layout(text, in: rect.insetBy(dx: 1, dy: 1)) {
        guard let path = WavyNumerals.path(for: glyph.character) else { continue }
        var transform = CGAffineTransform(a: glyph.frame.width, b: 0, c: 0, d: glyph.frame.height,
                                          tx: glyph.frame.minX, ty: glyph.frame.minY)
        guard let transformed = path.copy(using: &transform) else { continue }
        context.addPath(transformed)
        context.setLineWidth(max(0.8, glyph.frame.height * 0.075))
        context.strokePath()
    }
}
