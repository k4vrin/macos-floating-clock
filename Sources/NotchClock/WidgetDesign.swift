import AppKit

enum WidgetRenderer: String, Codable, Sendable { case flipDate, aiUsage }

struct WidgetDesign: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let renderer: WidgetRenderer
    let accent: String
    var provider: UsageProvider? = nil
    var usageProvider: UsageProvider { provider ?? .codex }
    static let originals = [
        WidgetDesign(id: "date", name: "The Daily One", renderer: .flipDate, accent: "D35C3F"),
        WidgetDesign(id: "usage", name: "Codex Desk", renderer: .aiUsage, accent: "9BAF84", provider: .codex),
        WidgetDesign(id: "claude-usage", name: "Claude Desk", renderer: .aiUsage, accent: "9BAF84", provider: .claude)
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
        case .aiUsage:
            let usage = UsageWidgetView(compact: compact)
            usage.provider = design.usageProvider
            view = usage
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
