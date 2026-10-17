import AppKit

enum ThemeMaterial: String, Codable, Sendable { case paperCut }
enum ThemeComponent { case clock, calendar, usage }

struct ComponentColors: Codable, Equatable, Sendable {
    let surface: String
    let ink: String
}

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
    var family: VisualFamily? = nil
    var material: ThemeMaterial? = nil
    var calendarColors: ComponentColors? = nil
    var usageColors: ComponentColors? = nil

    static let originals = [
        ThemeDesign(id: "original", name: "Original objects", shell: "0E0F0E", surface: "F0E6C4", ink: "1F211F",
                    text: "F0E6C4", muted: "918F85", clockAccent: "C93D33", widgetAccent: "D35C3F", usesDesignAccents: true, family: .wavy),
        ThemeDesign(id: "blue-hour", name: "Blue hour", shell: "142836", surface: "DDECF0", ink: "173D55",
                    text: "DDECF0", muted: "A0BBC7", clockAccent: "287EA5", widgetAccent: "347B92"),
        ThemeDesign(id: "plum", name: "Plum & brass", shell: "302332", surface: "F0E1D0", ink: "3D293E",
                    text: "F0E1D0", muted: "C3A8BB", clockAccent: "88516E", widgetAccent: "956742"),
        ThemeDesign(id: "counter", name: "Counter objects", shell: "182124", surface: "EFE5CA", ink: "20292B",
                    text: "EFE5CA", muted: "A6AAA3", clockAccent: "C48B36", widgetAccent: "C48B36", family: .counter),
        ThemeDesign(id: "paper-cut", name: "Paper Cut", shell: "EAE0CE", surface: "BC5938", ink: "FFF1D4",
                    text: "453D32", muted: "8C7963", clockAccent: "EBAE32", widgetAccent: "EBAE32", family: .wavy,
                    material: .paperCut, calendarColors: ComponentColors(surface: "F1C34F", ink: "164865"),
                    usageColors: ComponentColors(surface: "164865", ink: "FFF1D4"))
    ]

    var hasValidColors: Bool {
        let componentColors = [calendarColors, usageColors].compactMap { $0 }.flatMap { [$0.surface, $0.ink] }
        return ([shell, surface, ink, text, muted, clockAccent, widgetAccent] + componentColors).allSatisfy {
            $0.range(of: "^[A-Fa-f0-9]{6}$", options: .regularExpression) != nil
        }
    }
}

@MainActor
struct ThemePalette {
    let design: ThemeDesign
    private let component: ThemeComponent
    init(_ design: ThemeDesign = ThemeDesign.originals[0], component: ThemeComponent = .clock) {
        self.design = design
        self.component = component
    }
    private var componentColors: ComponentColors? {
        switch component {
        case .clock: nil
        case .calendar: design.calendarColors
        case .usage: design.usageColors
        }
    }
    var isPaperCut: Bool { design.material == .paperCut }
    var shell: NSColor { Self.color(design.shell) }
    var surface: NSColor { Self.color(componentColors?.surface ?? design.surface) }
    var ink: NSColor { Self.color(componentColors?.ink ?? design.ink) }
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
