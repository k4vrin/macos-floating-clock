import AppKit

@MainActor
class NotchItemView: NSView {
    var palette = ThemePalette() { didSet { needsDisplay = true } }
    var uses24HourTime = true { didSet { needsDisplay = true } }
    var date = Date() { didSet { needsDisplay = true } }
    var accent: NSColor = ThemePalette().clockAccent { didSet { needsDisplay = true } }
    var onPress: (() -> Void)?
    override var isFlipped: Bool { true }
    override func mouseDown(with event: NSEvent) { onPress?() }
    override func accessibilityPerformPress() -> Bool {
        guard let onPress else { return false }
        onPress()
        return true
    }
}

@MainActor
enum ClockViewFactory {
    static func make(_ design: ClockDesign, compact: Bool) -> NotchItemView {
        let view: NotchItemView
        switch design.renderer {
        case .wavyAnalog: view = compact ? CompactClockView() : ClockFaceView()
        case .capsuleDigital: view = DigitalClockView(compact: compact)
        }
        let rgb = UInt32(design.accent, radix: 16) ?? 0xC93D33
        view.accent = NSColor(srgbRed: Double((rgb >> 16) & 255) / 255,
                              green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255, alpha: 1)
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(compact ? .button : .image)
        return view
    }
}
