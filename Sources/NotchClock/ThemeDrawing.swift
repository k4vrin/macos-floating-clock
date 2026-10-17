import AppKit

func mix(_ start: CGFloat, _ end: CGFloat, _ progress: CGFloat) -> CGFloat {
    start + (end - start) * progress
}

func mix(_ start: NSRect, _ end: NSRect, _ progress: CGFloat) -> NSRect {
    NSRect(x: mix(start.minX, end.minX, progress), y: mix(start.minY, end.minY, progress),
           width: mix(start.width, end.width, progress), height: mix(start.height, end.height, progress))
}

/// A shared bezel and mounting seam keep all objects in a theme visually related.
@MainActor
func drawThemeHousing(in body: NSRect, palette: ThemePalette, accent: NSColor,
                      progress: CGFloat, mountOnLeft: Bool = false, sharedFrame: Bool = false) -> NSRect {
    if palette.isPaperCut { return drawPaperHousing(in: body, palette: palette, progress: progress, sharedFrame: sharedFrame) }
    let mount = mix(body.height * 0.18, 12, progress)
    let face = NSRect(x: body.minX + (mountOnLeft ? mount : 0), y: body.minY,
                      width: max(1, body.width - mount), height: body.height)
    let radius = mix(body.height / 2, min(body.width * 0.31, body.height / 2), progress)
    accent.setFill()
    NSBezierPath(roundedRect: face, xRadius: radius, yRadius: radius).fill()
    NSRect(x: mountOnLeft ? body.minX : face.midX, y: body.minY,
           width: mountOnLeft ? face.midX - body.minX : body.maxX - face.midX, height: body.height).fill()
    palette.ink.withAlphaComponent(0.4).setFill()
    NSRect(x: mountOnLeft ? body.minX + mount / 2 : body.maxX - mount / 2,
           y: body.minY, width: mix(0.5, 1, progress), height: body.height).fill()
    let rim = mix(1.5, 6, progress)
    let bezel = face.insetBy(dx: rim, dy: rim)
    palette.ink.setFill()
    NSBezierPath(roundedRect: bezel, xRadius: max(1, radius - rim), yRadius: max(1, radius - rim)).fill()
    let edge = mix(0.8, 2.5, progress)
    let dial = bezel.insetBy(dx: edge, dy: edge)
    NSGradient(starting: palette.highlight, ending: palette.surface)?.draw(
        in: NSBezierPath(roundedRect: dial, xRadius: max(1, radius - rim - edge),
                         yRadius: max(1, radius - rim - edge)), angle: 90)
    return dial
}

@MainActor
func drawThemeNumber(_ text: String, in rect: NSRect, family: VisualFamily, palette: ThemePalette) {
    if palette.isPaperCut {
        drawPaperNumber(text, in: rect, palette: palette)
    } else if family == .wavy {
        drawWavyNumerals(text, in: rect, color: palette.ink)
    } else {
        let count = max(1, text.count)
        let width = rect.width / CGFloat(count)
        for (index, character) in text.enumerated() {
            let tile = NSRect(x: rect.minX + CGFloat(index) * width + 0.5, y: rect.minY,
                              width: max(1, width - 1), height: rect.height)
            palette.ink.setFill()
            NSBezierPath(roundedRect: tile, xRadius: min(4, rect.height * 0.1), yRadius: min(4, rect.height * 0.1)).fill()
            let font = NSFont.monospacedDigitSystemFont(ofSize: min(rect.height * 0.78, width * 1.3), weight: .medium)
            drawText(String(character), at: NSRect(x: tile.minX, y: tile.midY - (font.ascender - font.descender) / 2,
                                                    width: tile.width, height: font.ascender - font.descender + 2),
                     font: font, color: palette.surface)
            palette.surface.withAlphaComponent(0.15).setFill()
            NSRect(x: tile.minX, y: tile.midY, width: tile.width, height: 0.6).fill()
        }
    }
}

// Cache one deterministic transparent grain tile; animation never rebuilds the texture.
@MainActor
private enum PaperGrain {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 64, height: 64))
        image.lockFocus()
        for index in 0..<520 {
            let x = CGFloat((index * 37 + index * index * 3) % 257) / 4
            let y = CGFloat((index * 71 + index * index * 7) % 251) / 4
            (index.isMultiple(of: 2) ? NSColor.white : NSColor.black).withAlphaComponent(0.06).setFill()
            NSRect(x: x, y: y, width: 0.5, height: 0.8).fill()
        }
        image.unlockFocus()
        return image
    }()
}

@MainActor
func paperBody(in bounds: NSRect, progress: CGFloat) -> NSRect {
    bounds.insetBy(dx: mix(0.5, 4, progress), dy: mix(0.5, 8, progress))
}

@MainActor
func drawPaperFrame(in body: NSRect, progress: CGFloat) {
    let radius = body.height * 0.28
    NSGraphicsContext.saveGraphicsState()
    let lift = NSShadow()
    lift.shadowColor = ThemePalette.color("493321").withAlphaComponent(0.25 * progress)
    lift.shadowBlurRadius = 6 * progress
    lift.shadowOffset = NSSize(width: 0, height: -3 * progress)
    lift.set()
    ThemePalette.color("DCCAA6").setFill()
    NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).fill()
    NSGraphicsContext.restoreGraphicsState()
    let top = body.insetBy(dx: 1, dy: 1).offsetBy(dx: 0, dy: -min(1, progress))
    ThemePalette.color("FFF0D3").setFill()
    NSBezierPath(roundedRect: top, xRadius: radius, yRadius: radius).fill()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: top, xRadius: radius, yRadius: radius).addClip()
    NSColor(patternImage: PaperGrain.image).setFill()
    top.fill()
    NSGraphicsContext.restoreGraphicsState()
}

@MainActor
func drawPaperHousing(in body: NSRect, palette: ThemePalette, progress: CGFloat, sharedFrame: Bool = false) -> NSRect {
    if !sharedFrame { drawPaperFrame(in: body, progress: progress) }
    let dial = body.insetBy(dx: mix(2.5, 6, progress), dy: mix(2.5, 6, progress))
    let radius = dial.height * 0.25
    let path = NSBezierPath(roundedRect: dial, xRadius: radius, yRadius: radius)
    let highlight = palette.surface.blended(withFraction: 0.04, of: .white) ?? palette.surface
    NSGradient(starting: highlight, ending: palette.surface)?.draw(in: path, angle: 90)
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSColor(patternImage: PaperGrain.image).setFill()
    dial.fill()
    // A narrow inner edge suggests stacked paper without making a second floating frame.
    palette.ink.withAlphaComponent(0.12).setStroke()
    path.lineWidth = mix(0.5, 1.5, progress)
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return dial
}

@MainActor
private func drawPaperNumber(_ text: String, in rect: NSRect, palette: ThemePalette) {
    let characters = Array(text)
    let weights = characters.map { $0 == ":" ? CGFloat(0.34) : $0 == "%" ? 0.9 : 0.86 }
    let unit = rect.width / max(1, weights.reduce(0, +))
    var x = rect.minX
    for (index, character) in characters.enumerated() {
        let width = unit * weights[index]
        let base = NSFont.systemFont(ofSize: rect.height * 1.03, weight: .heavy)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        var font = NSFont(descriptor: descriptor, size: base.pointSize) ?? base
        let measured = (String(character) as NSString).size(withAttributes: [.font: font]).width
        if measured > width * 0.96 { font = NSFont(descriptor: descriptor, size: font.pointSize * width * 0.96 / measured) ?? font }
        let height = font.ascender - font.descender
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext.current?.cgContext
        let center = CGPoint(x: x + width / 2, y: rect.midY)
        context?.translateBy(x: center.x, y: center.y)
        // Fixed per-glyph offsets give the chunky paper numerals hand-cut asymmetry.
        context?.rotate(by: [CGFloat(-0.035), 0.025, 0, -0.025, 0.035][index % 5])
        context?.scaleBy(x: 1, y: [CGFloat(1), 0.94, 1, 0.98, 0.95][index % 5])
        let shadow = NSShadow()
        shadow.shadowColor = ThemePalette.color("35251B").withAlphaComponent(0.4)
        shadow.shadowBlurRadius = min(3, rect.height * 0.035)
        shadow.shadowOffset = NSSize(width: 0, height: -min(3, rect.height * 0.035))
        shadow.set()
        drawText(String(character), at: NSRect(x: -width / 2, y: -height / 2, width: width, height: height + 2),
                 font: font, color: character == ":" ? palette.clockAccent : palette.ink)
        NSGraphicsContext.restoreGraphicsState()
        x += width
    }
}
