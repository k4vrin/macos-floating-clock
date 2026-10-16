import AppKit

/// Palettes are data-only plugins. They reuse native renderers and never load executable code.
struct ThemeDesign: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let shell: String
    let surface: String
    let ink: String
    let text: String
    let muted: String
    let clockAccent: String
    let widgetAccent: String
    var usesDesignAccents: Bool? = nil

    static let originals = [
        ThemeDesign(id: "original", name: "Original objects", shell: "0E0F0E", surface: "F0E6C4", ink: "1F211F",
                    text: "F0E6C4", muted: "918F85", clockAccent: "C93D33", widgetAccent: "D35C3F", usesDesignAccents: true),
        ThemeDesign(id: "blue-hour", name: "Blue hour", shell: "142836", surface: "DDECF0", ink: "173D55",
                    text: "DDECF0", muted: "A0BBC7", clockAccent: "287EA5", widgetAccent: "347B92"),
        ThemeDesign(id: "plum", name: "Plum & brass", shell: "302332", surface: "F0E1D0", ink: "3D293E",
                    text: "F0E1D0", muted: "C3A8BB", clockAccent: "88516E", widgetAccent: "956742")
    ]

    var hasValidColors: Bool {
        [shell, surface, ink, text, muted, clockAccent, widgetAccent].allSatisfy {
            $0.range(of: "^[A-Fa-f0-9]{6}$", options: .regularExpression) != nil
        }
    }
}

@MainActor
struct ThemePalette {
    let design: ThemeDesign
    init(_ design: ThemeDesign = ThemeDesign.originals[0]) { self.design = design }
    var shell: NSColor { Self.color(design.shell) }
    var surface: NSColor { Self.color(design.surface) }
    var ink: NSColor { Self.color(design.ink) }
    var text: NSColor { Self.color(design.text) }
    var muted: NSColor { Self.color(design.muted) }
    var clockAccent: NSColor { Self.color(design.clockAccent) }
    var widgetAccent: NSColor { Self.color(design.widgetAccent) }
    var highlight: NSColor { surface.blended(withFraction: 0.25, of: .white) ?? surface }

    static func color(_ hex: String) -> NSColor {
        let value = UInt32(hex, radix: 16) ?? 0
        return NSColor(srgbRed: Double((value >> 16) & 255) / 255,
                       green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255, alpha: 1)
    }
}
