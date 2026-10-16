import AppKit

struct SettingsChoice {
    let id: String
    let title: String
}

@MainActor
final class ThemeSampleView: NSView {
    var theme = ThemeDesign.originals[0] { didSet { needsDisplay = true } }
    override var intrinsicContentSize: NSSize { NSSize(width: 500, height: 72) }
    override func draw(_ dirtyRect: NSRect) {
        let palette = ThemePalette(theme)
        palette.shell.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12).fill()
        palette.clockAccent.setFill()
        NSBezierPath(roundedRect: NSRect(x: 16, y: 13, width: 98, height: 46), xRadius: 23, yRadius: 23).fill()
        palette.surface.setFill()
        NSBezierPath(roundedRect: NSRect(x: 20, y: 17, width: 78, height: 38), xRadius: 19, yRadius: 19).fill()
        drawText("10:10", at: NSRect(x: 25, y: 25, width: 66, height: 22),
                 font: .monospacedDigitSystemFont(ofSize: 18, weight: .medium), color: palette.ink)
        drawText(theme.name, at: NSRect(x: 134, y: 28, width: 250, height: 20),
                 font: .systemFont(ofSize: 15, weight: .medium), color: palette.text, alignment: .left)
        for (index, color) in [palette.surface, palette.clockAccent, palette.widgetAccent].enumerated() {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: bounds.width - 82 + CGFloat(index) * 22, y: 29, width: 14, height: 14)).fill()
        }
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    var onPreferencesChanged: ((AppPreferences) -> Void)?
    var onClockChanged: ((String) -> Void)?
    var onWidgetChanged: ((String) -> Void)?
    var onInstallPack: (() -> Void)?
    private var preferences = AppPreferences()
    private var themes: [String: ThemeDesign] = [:]
    private let display = NSPopUpButton()
    private let clock = NSPopUpButton()
    private let widget = NSPopUpButton()
    private let theme = NSPopUpButton()
    private let timeFormat = NSButton(checkboxWithTitle: "Use 24-hour time", target: nil, action: nil)
    private let motion = NSButton(checkboxWithTitle: "Reduce animations", target: nil, action: nil)
    private let startup = NSButton(checkboxWithTitle: "Start expanded", target: nil, action: nil)
    private let diagnostics = NSTextField(wrappingLabelWithString: "")
    private let sample = ThemeSampleView()

    init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 570, height: 560),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Wavy Clock Settings"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 24)
        ])
        let title = NSTextField(labelWithString: "Your objects of time")
        title.font = .systemFont(ofSize: 25, weight: .semibold)
        stack.addArrangedSubview(title)
        let subtitle = NSTextField(wrappingLabelWithString: "Choose where your clock lives and how it feels.")
        subtitle.textColor = .secondaryLabelColor
        stack.addArrangedSubview(subtitle)
        sample.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(sample)
        sample.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        for (index, label, popup) in [(0, "Display", display), (1, "Clock", clock),
                                      (2, "Right side", widget), (3, "Theme", theme)] {
            popup.tag = index
            popup.target = self
            popup.action = #selector(choiceChanged(_:))
            popup.setAccessibilityLabel(label)
            let text = NSTextField(labelWithString: label)
            text.widthAnchor.constraint(equalToConstant: 95).isActive = true
            let row = NSStackView(views: [text, popup])
            row.spacing = 12
            row.alignment = .centerY
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        diagnostics.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        diagnostics.textColor = .secondaryLabelColor
        stack.addArrangedSubview(diagnostics)
        diagnostics.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        let separator = NSBox()
        separator.boxType = .separator
        stack.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        for (index, button) in [timeFormat, motion, startup].enumerated() {
            button.tag = index
            button.target = self
            button.action = #selector(preferenceChanged(_:))
            stack.addArrangedSubview(button)
        }
        let install = NSButton(title: "Install theme or clock pack…", target: self, action: #selector(installPack))
        stack.addArrangedSubview(install)
        let help = NSTextField(wrappingLabelWithString: "Changes apply immediately and are saved. If your chosen display disconnects, the clock uses the built-in display until it returns.")
        help.font = .systemFont(ofSize: 11)
        help.textColor = .secondaryLabelColor
        stack.addArrangedSubview(help)
        help.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        window.center()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(preferences: AppPreferences, displays: [SettingsChoice], clocks: [SettingsChoice],
                widgets: [SettingsChoice], themes: [(SettingsChoice, ThemeDesign)],
                selectedClock: String, selectedWidget: String, geometryDescription: String) {
        self.preferences = preferences
        self.themes = Dictionary(uniqueKeysWithValues: themes.map { ($0.0.id, $0.1) })
        populate(display, choices: displays, selected: preferences.display)
        populate(clock, choices: clocks, selected: selectedClock)
        populate(widget, choices: widgets, selected: selectedWidget)
        populate(theme, choices: themes.map(\.0), selected: preferences.theme)
        sample.theme = self.themes[preferences.theme] ?? ThemeDesign.originals[0]
        diagnostics.stringValue = geometryDescription
        timeFormat.state = preferences.uses24HourTime ? .on : .off
        motion.state = preferences.reduceMotion ? .on : .off
        startup.state = preferences.startExpanded ? .on : .off
    }

    private func populate(_ popup: NSPopUpButton, choices: [SettingsChoice], selected: String) {
        popup.removeAllItems()
        for choice in choices {
            popup.addItem(withTitle: choice.title)
            popup.lastItem?.representedObject = choice.id
        }
        if let item = popup.itemArray.first(where: { $0.representedObject as? String == selected }) {
            popup.select(item)
        } else {
            popup.addItem(withTitle: "Unavailable · saved selection")
            popup.lastItem?.representedObject = selected
            popup.select(popup.lastItem)
        }
    }

    @objc private func choiceChanged(_ sender: NSPopUpButton) {
        guard let key = sender.selectedItem?.representedObject as? String else { return }
        switch sender.tag {
        case 0: preferences.display = key; onPreferencesChanged?(preferences)
        case 1: onClockChanged?(key)
        case 2: onWidgetChanged?(key)
        default:
            preferences.theme = key
            sample.theme = themes[key] ?? ThemeDesign.originals[0]
            onPreferencesChanged?(preferences)
        }
    }

    @objc private func preferenceChanged(_ sender: NSButton) {
        switch sender.tag {
        case 0: preferences.uses24HourTime = sender.state == .on
        case 1: preferences.reduceMotion = sender.state == .on
        default: preferences.startExpanded = sender.state == .on
        }
        onPreferencesChanged?(preferences)
    }
    @objc private func installPack() { onInstallPack?() }
}
