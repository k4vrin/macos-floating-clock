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
                      progress: CGFloat, mountOnLeft: Bool = false) -> NSRect {
    if palette.isPaperCut { return drawPaperHousing(in: body, palette: palette, progress: progress) }
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
func drawPaperHousing(in body: NSRect, palette: ThemePalette, progress: CGFloat) -> NSRect {
    let radius = body.height / 2
    let rim = ThemePalette.color("FFF1D4")
    NSGraphicsContext.saveGraphicsState()
    let lift = NSShadow()
    lift.shadowColor = ThemePalette.color("493321").withAlphaComponent(0.28 * progress)
    lift.shadowBlurRadius = 7 * progress
    lift.shadowOffset = NSSize(width: 0, height: -4 * progress)
    lift.set()
    rim.setFill()
    NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).fill()
    NSGraphicsContext.restoreGraphicsState()
    let layer = body.insetBy(dx: mix(1, 3, progress), dy: mix(1, 3, progress))
    ThemePalette.color("DCCAA6").setFill()
    NSBezierPath(roundedRect: layer, xRadius: layer.height / 2, yRadius: layer.height / 2).fill()
    let dial = body.insetBy(dx: mix(2.5, 9, progress), dy: mix(2.5, 9, progress))
    let path = NSBezierPath(roundedRect: dial, xRadius: dial.height / 2, yRadius: dial.height / 2)
    NSGradient(starting: palette.highlight, ending: palette.surface)?.draw(in: path, angle: 90)
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSColor(patternImage: PaperGrain.image).setFill()
    dial.fill()
    NSGraphicsContext.restoreGraphicsState()
    rim.withAlphaComponent(0.65).setStroke()
    let edge = NSBezierPath(roundedRect: body.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
    edge.lineWidth = mix(0.5, 1, progress)
    edge.stroke()
    return dial
}

@MainActor
private func drawPaperNumber(_ text: String, in rect: NSRect, palette: ThemePalette) {
    let base = NSFont.systemFont(ofSize: rect.height * 0.86, weight: .heavy)
    let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
    var font = NSFont(descriptor: descriptor, size: base.pointSize) ?? base
    let width = (text as NSString).size(withAttributes: [.font: font]).width
    if width > rect.width { font = NSFont(descriptor: descriptor, size: font.pointSize * rect.width / width) ?? font }
    let height = font.ascender - font.descender
    let frame = NSRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height + 2)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = ThemePalette.color("35251B").withAlphaComponent(0.35)
    shadow.shadowBlurRadius = min(3, rect.height * 0.035)
    shadow.shadowOffset = NSSize(width: 0, height: -min(2, rect.height * 0.025))
    shadow.set()
    drawText(text, at: frame, font: font, color: palette.ink)
    NSGraphicsContext.restoreGraphicsState()
}
