import AppKit

@MainActor
final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}

@MainActor
final class ClockContentView: NSView {
    private var palette = ThemePalette()
    var uses24HourTime = true { didSet { configureFormatters() } }
    var visualFamily = VisualFamily.wavy {
        didSet {
            for view in [face, compactClock, compactWidget, expandedWidget] {
                view.visualFamily = visualFamily
            }
        }
    }
    var reduceMotion = false
    var packName = "Originals" { didSet { needsDisplay = true } }
    private var design = ClockPack.builtIn.clocks[0]
    private var face: NotchItemView = ClockViewFactory.make(ClockPack.builtIn.clocks[0], compact: false)
    private let timeLabel = NSTextField(labelWithString: "")
    private var compactClock: NotchItemView = ClockViewFactory.make(ClockPack.builtIn.clocks[0], compact: true)
    private let collapseButton = NSButton(title: "Collapse  ↑", target: nil, action: nil)
    private let detail = FlippedContainerView()
    private let timeFormatter = DateFormatter()
    private var widgetDesign = WidgetDesign.originals[0]
    private var compactWidget = WidgetViewFactory.make(WidgetDesign.originals[0], compact: true)
    private var expandedWidget = WidgetViewFactory.make(WidgetDesign.originals[0], compact: false)
    private var usage: [UsageProvider: UsageSnapshot] = [:]
    private var usageStatus: [UsageProvider: String] = [:]
    var onToggle: (() -> Void)?
    var barHeight: CGFloat = 0
    var notchGap: CGFloat = 0
    var expanded = false
    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.cornerRadius = 0
        layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer?.masksToBounds = true
        addSubview(detail)
        detail.wantsLayer = true
        detail.addSubview(face)
        detail.addSubview(timeLabel)
        detail.addSubview(expandedWidget)
        addSubview(compactClock)
        addSubview(compactWidget)
        compactClock.onPress = { [weak self] in self?.onToggle?() }
        compactWidget.onPress = { [weak self] in self?.onToggle?() }
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .light)
        timeLabel.textColor = palette.surface
        collapseButton.bezelStyle = .inline
        collapseButton.isBordered = false
        collapseButton.font = .systemFont(ofSize: 11, weight: .medium)
        collapseButton.contentTintColor = palette.surface
        collapseButton.target = self
        collapseButton.action = #selector(toggle)
        collapseButton.setAccessibilityLabel("Collapse clock")
        detail.addSubview(collapseButton)
        configureFormatters()
        update(date: Date())
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func select(_ design: ClockDesign) {
        self.design = design
        face.removeFromSuperview()
        compactClock.removeFromSuperview()
        face = ClockViewFactory.make(design, compact: false)
        compactClock = ClockViewFactory.make(design, compact: true)
        compactClock.onPress = { [weak self] in self?.onToggle?() }
        detail.addSubview(face)
        addSubview(compactClock)
        applyTheme(palette.design)
        update(date: Date())
        needsLayout = true
    }

    func selectWidget(_ design: WidgetDesign) {
        widgetDesign = design
        compactWidget.removeFromSuperview()
        expandedWidget.removeFromSuperview()
        compactWidget = WidgetViewFactory.make(design, compact: true)
        expandedWidget = WidgetViewFactory.make(design, compact: false)
        compactWidget.onPress = { [weak self] in self?.onToggle?() }
        addSubview(compactWidget)
        detail.addSubview(expandedWidget)
        applyUsage(usage, status: usageStatus)
        applyTheme(palette.design)
        update(date: Date())
        needsLayout = true
    }

    func applyUsage(_ snapshots: [UsageProvider: UsageSnapshot], status: [UsageProvider: String]) {
        usage = snapshots
        usageStatus = status
        for view in [compactWidget, expandedWidget] {
            if view.snapshots != snapshots { view.snapshots = snapshots }
            if view.providerStatus != status { view.providerStatus = status }
            view.updateAccessibility()
        }
    }

    func applyTheme(_ theme: ThemeDesign) {
        palette = ThemePalette(theme)
        for view in [face, compactClock, compactWidget, expandedWidget] {
            view.visualFamily = visualFamily
            view.palette = palette
            view.uses24HourTime = uses24HourTime
        }
        let clockAccent = theme.usesDesignAccents == true ? ThemePalette.color(design.accent) : palette.clockAccent
        face.accent = clockAccent
        compactClock.accent = clockAccent
        let widgetAccent = theme.usesDesignAccents == true ? ThemePalette.color(widgetDesign.accent) : palette.widgetAccent
        compactWidget.accent = widgetAccent
        expandedWidget.accent = widgetAccent
        timeLabel.textColor = palette.text
        collapseButton.contentTintColor = palette.text
        needsDisplay = true
    }

    func configureFormatters() {
        // An explicit app hour-format choice must override the system hour-cycle preference.
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = .current
        timeFormatter.dateFormat = uses24HourTime ? "HH:mm" : "h:mm a"
        face.uses24HourTime = uses24HourTime
        compactClock.uses24HourTime = uses24HourTime
        compactWidget.needsDisplay = true
        expandedWidget.needsDisplay = true
    }

    func update(date: Date) {
        face.date = date
        compactClock.date = date
        let time = timeFormatter.string(from: date)
        compactClock.setAccessibilityLabel("Expand \(design.name), \(time)")
        if timeLabel.stringValue != time {
            timeLabel.stringValue = time
        }
        for view in [compactWidget, expandedWidget] {
            // Date cards change daily; usage freshness changes by the minute, even in the expanded host.
            let component: Calendar.Component = widgetDesign.renderer == .flipDate ? .day : .minute
            if !Calendar.current.isDate(view.date, equalTo: date, toGranularity: component) || view.accessibilityLabel() == nil {
                view.date = date
            }
            view.updateAccessibility()
        }
        face.setAccessibilityElement(true)
        face.setAccessibilityRole(.image)
        face.setAccessibilityLabel("\(design.name), \(time)")
    }

    func setExpanded(_ value: Bool, animated: Bool) {
        expanded = value
        detail.setAccessibilityHidden(!value)
        if value { detail.isHidden = false }
        let reduced = reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animated && !reduced ? 0.24 : 0
            detail.animator().alphaValue = value ? 1 : 0
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, !self.expanded else { return }
                self.detail.isHidden = true
            }
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let middle = bounds.midX
        compactClock.frame = NSRect(x: middle - notchGap / 2 - 84, y: 0, width: 84, height: barHeight)
        compactWidget.frame = NSRect(x: middle + notchGap / 2 + 2, y: 0, width: 108, height: barHeight)
        detail.frame = NSRect(x: 0, y: barHeight, width: bounds.width, height: 390)
        face.frame = NSRect(x: 32, y: 42, width: 292, height: 292)
        timeLabel.frame = NSRect(x: 365, y: 34, width: 230, height: 25)
        expandedWidget.frame = NSRect(x: 355, y: 73, width: 250, height: 266)
        collapseButton.frame = NSRect(x: 517, y: 349, width: 100, height: 24)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if !expanded {
            // The left wing is the clock object itself. Keep its silhouette visible against the desktop.
            palette.shell.setFill()
            let rightWing = NSRect(x: bounds.midX - notchGap / 2, y: 0,
                                   width: notchGap + 112, height: bounds.height)
            NSBezierPath(roundedRect: rightWing, xRadius: bounds.height / 2,
                         yRadius: bounds.height / 2).fill()
            NSRect(x: bounds.midX - notchGap / 2, y: 0,
                   width: notchGap, height: bounds.height).fill()
            return
        }
        let radius = min(CGFloat(26), bounds.height / 2)
        let shell = NSBezierPath()
        shell.move(to: .zero)
        shell.line(to: CGPoint(x: bounds.width, y: 0))
        shell.line(to: CGPoint(x: bounds.width, y: bounds.height - radius))
        shell.curve(to: CGPoint(x: bounds.width - radius, y: bounds.height),
                    controlPoint1: CGPoint(x: bounds.width, y: bounds.height - radius * 0.45),
                    controlPoint2: CGPoint(x: bounds.width - radius * 0.45, y: bounds.height))
        shell.line(to: CGPoint(x: radius, y: bounds.height))
        shell.curve(to: CGPoint(x: 0, y: bounds.height - radius),
                    controlPoint1: CGPoint(x: radius * 0.45, y: bounds.height),
                    controlPoint2: CGPoint(x: 0, y: bounds.height - radius * 0.45))
        shell.close()
        palette.shell.setFill()
        shell.fill()
        guard expanded else { return }
        let top = barHeight
        drawText("OBJECTS OF TIME", at: NSRect(x: 31, y: top + 14, width: 170, height: 15),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: palette.muted, alignment: .left)
        NSColor.white.withAlphaComponent(0.08).setFill()
        NSRect(x: 32, y: top + 347, width: 576, height: 1).fill()
        drawText(packName.uppercased(), at: NSRect(x: 34, y: top + 361, width: 100, height: 15),
                 font: .systemFont(ofSize: 10, weight: .semibold), color: palette.text, alignment: .left)
        drawText("CLOCK STUDY  /  001", at: NSRect(x: 180, y: top + 361, width: 210, height: 15),
                 font: .systemFont(ofSize: 9, weight: .regular), color: palette.muted, alignment: .left)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if point.y < barHeight { onToggle?() }
    }

    @objc private func toggle() { onToggle?() }
}
