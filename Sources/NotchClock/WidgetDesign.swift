import AppKit

enum WidgetRenderer: String, Codable, Sendable { case flipDate, aiUsage }

struct WidgetDesign: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let renderer: WidgetRenderer
    let accent: String
    static let originals = [
        WidgetDesign(id: "date", name: "The Daily One", renderer: .flipDate, accent: "D35C3F"),
        WidgetDesign(id: "usage", name: "The AI Desk", renderer: .aiUsage, accent: "9BAF84")
    ]
}

@MainActor
class WidgetSurfaceView: NotchItemView {
    var displayName = ""
    let compact: Bool
    var snapshots: [UsageProvider: UsageSnapshot] = [:] { didSet { needsDisplay = true } }
    var providerStatus: [UsageProvider: String] = [:] { didSet { needsDisplay = true } }

    init(compact: Bool) {
        self.compact = compact
        super.init(frame: .zero)
        expansionProgress = compact ? 0 : 1
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateAccessibility() { }
}

@MainActor
enum WidgetViewFactory {
    static func make(_ design: WidgetDesign, compact: Bool) -> WidgetSurfaceView {
        let view: WidgetSurfaceView
        switch design.renderer {
        case .flipDate: view = DateWidgetView(compact: compact)
        case .aiUsage: view = UsageWidgetView(compact: compact)
        }
        view.displayName = design.name
        let rgb = UInt32(design.accent, radix: 16) ?? 0xD35C3F
        view.accent = NSColor(srgbRed: Double((rgb >> 16) & 255) / 255,
                              green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255, alpha: 1)
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(compact ? .button : .image)
        return view
    }
}
