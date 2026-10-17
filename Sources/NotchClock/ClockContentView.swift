import AppKit

@MainActor
final class ClockContentView: NSView {
    private var palette = ThemePalette()
    var uses24HourTime = true { didSet { configureFormatters() } }
    var visualFamily = VisualFamily.wavy {
        didSet { clock.visualFamily = visualFamily; widget.visualFamily = visualFamily }
    }
    var reduceMotion = false
    var packName = "Originals" { didSet { needsDisplay = true } }
    private var design = ClockPack.builtIn.clocks[0]
    private var clock: NotchItemView = CompactClockView()
    private var widgetDesign = WidgetDesign.originals[0]
    private var widget = WidgetViewFactory.make(WidgetDesign.originals[0], compact: true)
    private let timeFormatter = DateFormatter()
    private var usage: [UsageProvider: UsageSnapshot] = [:]
    private var usageStatus: [UsageProvider: String] = [:]
    private var hoverArea: NSTrackingArea?
    var onToggle: (() -> Void)?
    var onHoverChanged: ((NSEvent) -> Void)?
    var barHeight: CGFloat = 0
    var notchGap: CGFloat = 0
    private(set) var expanded = false
    private(set) var progress: CGFloat = 0
    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        addSubview(clock)
        addSubview(widget)
        widget.setAccessibilityRole(.image)
        configureFormatters()
        applyTheme(palette.design)
        update(date: Date())
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
        super.updateTrackingAreas()
    }
    override func mouseEntered(with event: NSEvent) { onHoverChanged?(event) }
    override func mouseExited(with event: NSEvent) { onHoverChanged?(event) }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // The camera cutout is never an interactive part of the bar, even during motion.
        if point.y < barHeight && abs(point.x - bounds.midX) < notchGap / 2 { return nil }
        return super.hitTest(point)
    }

    func select(_ design: ClockDesign) {
        self.design = design
        clock.removeFromSuperview()
        clock = ClockViewFactory.make(design, compact: true)
        addSubview(clock)
        applyTheme(palette.design)
        update(date: Date())
        setProgress(progress)
    }
    func selectWidget(_ design: WidgetDesign) {
        widgetDesign = design
        widget.removeFromSuperview()
        widget = WidgetViewFactory.make(design, compact: true)
        addSubview(widget)
        widget.setAccessibilityRole(.image)
        applyUsage(usage, status: usageStatus)
        applyTheme(palette.design)
        update(date: Date())
        setProgress(progress)
    }
    func applyUsage(_ snapshots: [UsageProvider: UsageSnapshot], status: [UsageProvider: String]) {
        usage = snapshots; usageStatus = status
        if widget.snapshots != snapshots { widget.snapshots = snapshots }
        if widget.providerStatus != status { widget.providerStatus = status }
        widget.updateAccessibility()
    }
    func applyTheme(_ theme: ThemeDesign) {
        palette = ThemePalette(theme)
        let accent = theme.usesDesignAccents == true ? ThemePalette.color(design.accent) : palette.clockAccent
        // Every component uses the theme's same housing accent; widget data never picks its own style.
        for view in [clock, widget] {
            view.visualFamily = visualFamily
            view.palette = palette
            view.uses24HourTime = uses24HourTime
            view.accent = accent
        }
        needsDisplay = true
    }
    func configureFormatters() {
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = .current
        timeFormatter.dateFormat = uses24HourTime ? "HH:mm" : "h:mm a"
        clock.uses24HourTime = uses24HourTime
    }
    func update(date: Date) {
        clock.date = date
        clock.setAccessibilityElement(true)
        clock.setAccessibilityRole(.image)
        clock.setAccessibilityLabel("\(design.name), \(timeFormatter.string(from: date))")
        let component: Calendar.Component = widgetDesign.renderer == .flipDate ? .day : .minute
        if !Calendar.current.isDate(widget.date, equalTo: date, toGranularity: component) || widget.accessibilityLabel() == nil {
            widget.date = date
        }
        widget.updateAccessibility()
    }
    func setExpanded(_ value: Bool, animated: Bool) {
        expanded = value
        if !animated { setProgress(value ? 1 : 0) }
    }
    func setProgress(_ value: CGFloat) {
        progress = min(1, max(0, value))
        clock.expansionProgress = progress
        widget.expansionProgress = progress
        needsLayout = true
        needsDisplay = true
    }
    override func layout() {
        super.layout()
        let left = NSRect(x: bounds.midX - notchGap / 2 - 84, y: 0, width: 84, height: barHeight)
        let right = NSRect(x: bounds.midX + notchGap / 2 + 2, y: 0, width: 108, height: barHeight)
        let scale = min(1, bounds.width / 640)
        clock.frame = mix(left, NSRect(x: 32 * scale, y: barHeight + 42,
                                      width: 292 * scale, height: 292), progress)
        widget.frame = mix(right, NSRect(x: 326 * scale, y: barHeight + 42,
                                        width: 282 * scale, height: 292), progress)
    }
    override func draw(_ dirtyRect: NSRect) {
        let radius = min(mix(barHeight / 2, 26, progress), bounds.height / 2)
        // Grow the shell from the notch bridge while the two objects move out into the desk.
        let shell = NSRect(x: mix(bounds.midX - notchGap / 2, 0, progress), y: 0,
                           width: mix(notchGap + 112, bounds.width, progress), height: bounds.height)
        palette.shell.setFill()
        NSBezierPath(roundedRect: shell, xRadius: radius, yRadius: radius).fill()
        NSRect(x: shell.minX, y: 0, width: shell.width, height: min(barHeight, shell.height)).fill()
        drawText("OBJECTS OF TIME", at: NSRect(x: 32, y: barHeight + 14, width: 170, height: 15),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: palette.muted.withAlphaComponent(max(0, (progress - 0.7) / 0.3)))
        drawText(packName.uppercased(), at: NSRect(x: 32, y: barHeight + 361, width: 240, height: 15),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: palette.text.withAlphaComponent(progress), alignment: .left)
    }
}
