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
    if family == .wavy {
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
