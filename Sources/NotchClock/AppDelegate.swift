import AppKit
import QuartzCore

@MainActor
final class ClockPanel: NSPanel {
    var onPointerEvent: ((NSEvent) -> Void)?
    override func sendEvent(_ event: NSEvent) {
        if [.mouseMoved, .leftMouseDragged, .leftMouseDown, .rightMouseDown].contains(event.type) {
            onPointerEvent?(event)
        }
        super.sendEvent(event)
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let packStore = ClockPackStore(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("WavyClock/ClockPacks", isDirectory: true))
    private var packs = [ClockPack.builtIn]
    private var selectedKey = "dev.kavrin.originals/wavy"
    private var clockMenu = NSMenu()
    private var widgetMenu = NSMenu()
    private var selectedWidgetKey = "dev.kavrin.originals/date"
    private let usageClient = CodexUsageClient()
    private var usageSnapshots: [UsageProvider: UsageSnapshot] = [:]
    private var usageStatus: [UsageProvider: String] = [:]
    private var lastUsageRead = Date.distantPast
    private var lastCodexRequest = Date.distantPast
    private var codexEnabled = false
    private var panel: ClockPanel!
    private var content: ClockContentView!
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var probe: PerformanceProbe?
    private let morph = MorphTransition()
    private var hoverExit: Timer?
    private var globalPointerMonitor: Any?
    private var localPointerMonitor: Any?
    private var menuTracking = false
    private var expanded = false
    private var visible = true
    private var sleeping = false
    private var preferences = AppPreferences()
    private var settingsController: SettingsWindowController?
    private var selectedScreenName = ""
    private var geometry: BarGeometry?
    private let geometryResolver = MenuBarGeometryResolver()
    private var geometryUpdatePending = false
    private var presentationObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        content = ClockContentView(frame: NSRect(x: 0, y: 0, width: 640, height: 390))
        content.onHoverChanged = { [weak self] event in
            guard let self else { return }
            self.evaluateHover(at: self.panel.convertPoint(toScreen: event.locationInWindow))
        }
        morph.onUpdate = { [weak self] progress in
            guard let self else { return }
            self.content.setProgress(progress)
            self.applyFrame(animated: false)
        }
        panel = ClockPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
        panel.onPointerEvent = { [weak self] event in
            guard let self else { return }
            self.evaluateHover(at: self.panel.convertPoint(toScreen: event.locationInWindow))
        }
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        // This prototype occupies menu-bar space. It does not use shielding/system-security levels.
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary]
        panel.contentView = content
        let installed = packStore.installed()
        packs += installed.packs
        for warning in installed.warnings { NSLog("Clock pack skipped: %@", warning) }
        selectedKey = UserDefaults.standard.string(forKey: "selectedClock") ?? selectedKey
        if ProcessInfo.processInfo.arguments.contains("--digital") { selectedKey = "dev.kavrin.originals/digital" }
        if let design = design(for: selectedKey) {
            content.packName = packs.first(where: { selectedKey.hasPrefix($0.id + "/") })?.name ?? "Originals"
            content.select(design)
        }
        else { selectedKey = "dev.kavrin.originals/wavy" }
        selectedWidgetKey = UserDefaults.standard.string(forKey: "selectedWidget") ?? selectedWidgetKey
        if ProcessInfo.processInfo.arguments.contains("--usage-widget") { selectedWidgetKey = "dev.kavrin.originals/usage" }
        if let widget = widgetDesign(for: selectedWidgetKey) { content.selectWidget(widget) }
        else { selectedWidgetKey = "dev.kavrin.originals/date" }
        applyPreferences()
        codexEnabled = UserDefaults.standard.bool(forKey: "codexUsageEnabled")
        setupMenu()
        observeEvents()
        reconcileScreen()
        if geometry != nil { panel.orderFrontRegardless() }
        content.setExpanded(false, animated: false)
        refresh()

        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--render-previews"), args.indices.contains(index + 1) {
            renderPreviews(to: URL(fileURLWithPath: args[index + 1]))
            NSApp.terminate(nil)
        } else if let index = args.firstIndex(of: "--performance-probe"), args.indices.contains(index + 1) {
            probe = PerformanceProbe(output: URL(fileURLWithPath: args[index + 1]),
                                     toggle: { [weak self] in self?.toggleExpanded() })
            probe?.start()
        }
        evaluateHover()
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Wavy Clock")
        let menu = NSMenu()
        for (title, selector, key) in [("Show / Hide", #selector(toggleVisible), "h"),
                                       ("Quit Wavy Clock", #selector(quit), "q")] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
            item.target = self
            menu.addItem(item)
        }
        menu.insertItem(.separator(), at: 1)
        let clocks = NSMenuItem(title: "Clocks", action: nil, keyEquivalent: "")
        clocks.submenu = clockMenu
        menu.insertItem(clocks, at: 2)
        let install = NSMenuItem(title: "Install Theme or Clock Pack…", action: #selector(installPack), keyEquivalent: "")
        install.target = self
        menu.insertItem(install, at: 3)
        let widgets = NSMenuItem(title: "Right-side Widgets", action: nil, keyEquivalent: "")
        widgets.submenu = widgetMenu
        menu.insertItem(widgets, at: 4)
        for (offset, title, selector) in [
            (5, "Connect / Refresh Codex Usage", #selector(refreshUsageNow)),
            (6, "Claude Connection Instructions…", #selector(showClaudeInstructions)),
            (7, "Disconnect Codex Usage", #selector(disconnectCodex))
        ] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            menu.insertItem(item, at: offset)
        }
        menu.insertItem(.separator(), at: 8)
        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.insertItem(settings, at: 9)
        rebuildClockMenu()
        statusItem.menu = menu
        content.menu = menu
        menu.delegate = self
    }

    private func design(for key: String) -> ClockDesign? {
        for pack in packs {
            if let clock = pack.clocks.first(where: { pack.id + "/" + $0.id == key }) { return clock }
        }
        return nil
    }

    private func rebuildClockMenu() {
        widgetMenu.removeAllItems()
        for pack in packs where !(pack.widgets ?? []).isEmpty {
            let group = NSMenuItem(title: pack.name, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            group.submenu = submenu
            for widget in pack.widgets ?? [] {
                let key = pack.id + "/" + widget.id
                let item = NSMenuItem(title: widget.name, action: #selector(selectWidget(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = key
                item.state = key == selectedWidgetKey ? .on : .off
                submenu.addItem(item)
            }
            widgetMenu.addItem(group)
        }
        clockMenu.removeAllItems()
        for pack in packs where !pack.clocks.isEmpty {
            let group = NSMenuItem(title: pack.name, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            group.submenu = submenu
            for clock in pack.clocks {
                let key = pack.id + "/" + clock.id
                let item = NSMenuItem(title: clock.name, action: #selector(selectClock(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = key
                item.state = key == selectedKey ? .on : .off
                submenu.addItem(item)
            }
            clockMenu.addItem(group)
        }
    }

    @objc private func selectClock(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String, let design = design(for: key) else { return }
        selectedKey = key
        UserDefaults.standard.set(key, forKey: "selectedClock")
        content.packName = packs.first(where: { key.hasPrefix($0.id + "/") })?.name ?? "Originals"
        content.select(design)
        applyPreferences()
        rebuildClockMenu()
        updateSettings()
        refresh()
    }

    private func widgetDesign(for key: String) -> WidgetDesign? {
        for pack in packs {
            if let widget = (pack.widgets ?? []).first(where: { pack.id + "/" + $0.id == key }) { return widget }
        }
        return nil
    }

    @objc private func selectWidget(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String, let design = widgetDesign(for: key) else { return }
        selectedWidgetKey = key
        UserDefaults.standard.set(key, forKey: "selectedWidget")
        content.selectWidget(design)
        applyPreferences()
        updateSettings()
        if design.renderer != .aiUsage || design.usageProvider != .codex { usageClient.cancel() }
        lastUsageRead = .distantPast
        rebuildClockMenu()
        refresh()
    }

    private func refreshUsage(at date: Date, force: Bool = false) {
        guard let widget = widgetDesign(for: selectedWidgetKey), widget.renderer == .aiUsage,
              visible, !sleeping else { return }
        let provider = widget.usageProvider
        if force || date.timeIntervalSince(lastUsageRead) >= 60 {
            lastUsageRead = date
            if let snapshot = UsageCache.standard.load(provider) {
                usageSnapshots[provider] = snapshot
                if provider == .claude { usageStatus[provider] = "Status-line cache" }
                else if usageStatus[provider] == nil { usageStatus[provider] = "Cached" }
            }
            content.applyUsage(usageSnapshots, status: usageStatus)
        }
        guard provider == .codex, codexEnabled, !usageClient.isRunning, force || date.timeIntervalSince(lastCodexRequest) >= 60 else { return }
        lastCodexRequest = date
        usageStatus[.codex] = "Refreshing"
        content.applyUsage(usageSnapshots, status: usageStatus)
        usageClient.fetch { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let snapshot):
                self.usageSnapshots[.codex] = snapshot
                self.usageStatus[.codex] = snapshot.windows.isEmpty ? "No subscription limits" : "Live · just refreshed"
                do { try UsageCache.standard.save(snapshot) }
                catch { self.usageStatus[.codex] = "Live · cache save failed" }
            case .failure:
                self.usageStatus[.codex] = self.usageSnapshots[.codex] == nil ? "Unavailable · retry from menu" : "Cached · refresh failed"
            }
            self.content.applyUsage(self.usageSnapshots, status: self.usageStatus)
        }
    }

    @objc private func refreshUsageNow() {
        codexEnabled = true
        UserDefaults.standard.set(true, forKey: "codexUsageEnabled")
        if widgetDesign(for: selectedWidgetKey)?.renderer != .aiUsage ||
            widgetDesign(for: selectedWidgetKey)?.usageProvider != .codex {
            selectedWidgetKey = "dev.kavrin.originals/usage"
            UserDefaults.standard.set(selectedWidgetKey, forKey: "selectedWidget")
            content.selectWidget(WidgetDesign.originals[1])
            rebuildClockMenu()
        }
        refreshUsage(at: Date(), force: true)
    }

    @objc private func disconnectCodex() {
        usageClient.cancel()
        codexEnabled = false
        UserDefaults.standard.set(false, forKey: "codexUsageEnabled")
        usageStatus[.codex] = "Disconnected · cached"
        content.applyUsage(usageSnapshots, status: usageStatus)
    }

    @objc private func showClaudeInstructions() {
        let alert = NSAlert()
        alert.messageText = "Connect Claude Code's status line"
        alert.informativeText = "Set Claude Code's statusLine command to this app's executable followed by --capture-claude-usage. " +
            "The command stores only subscription percentages and reset times. It does not read credentials or prompts. " +
            "If you already use a status-line command, chain the capture command as described in docs/RIGHT_SIDE_WIDGETS.md. " +
            "Wavy Clock never changes your Claude settings automatically."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Copy Capture Command")
        if alert.runModal() == .alertSecondButtonReturn, let executable = Bundle.main.executableURL {
            let quoted = "'" + executable.path.replacingOccurrences(of: "'", with: "'\"'\"'") + "' --capture-claude-usage"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(quoted, forType: .string)
        }
    }

    @objc private func installPack() {
        let picker = NSOpenPanel()
        picker.title = "Install Theme or Clock Pack"
        picker.message = "Choose a theme, clock, or widget pack JSON manifest."
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard picker.runModal() == .OK, let url = picker.url else { return }
        do {
            let pack = try packStore.install(manifest: url)
            packs.append(pack)
            applyPreferences()
            rebuildClockMenu()
            updateSettings()
            let alert = NSAlert()
            alert.messageText = "Installed " + pack.name
            alert.informativeText = "Choose a design in Settings or from the menu → " + pack.name + "."
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Could not install clock pack"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func applyPreferences() {
        content.uses24HourTime = preferences.uses24HourTime
        content.reduceMotion = preferences.reduceMotion
        content.visualFamily = preferences.visualFamily
        let selected = packs.flatMap { pack in (pack.themes ?? []).map { (pack.id + "/" + $0.id, $0) } }
            .first { $0.0 == preferences.theme }?.1 ?? ThemeDesign.originals[0]
        content.applyTheme(selected)
        applyFrame(animated: false)
    }

    @objc private func showSettings() {
        if settingsController == nil {
            let controller = SettingsWindowController()
            controller.onPreferencesChanged = { [weak self] preferences in
                guard let self else { return }
                self.preferences = preferences
                preferences.save()
                self.applyPreferences()
                self.reconcileScreen()
                self.refresh()
                self.updateSettings()
            }
            controller.onClockChanged = { [weak self] key in
                let item = NSMenuItem(); item.representedObject = key
                self?.selectClock(item)
            }
            controller.onWidgetChanged = { [weak self] key in
                let item = NSMenuItem(); item.representedObject = key
                self?.selectWidget(item)
            }
            controller.onInstallPack = { [weak self] in self?.installPack() }
            settingsController = controller
        }
        updateSettings()
        NSApp.activate(ignoringOtherApps: true)
        settingsController?.showWindow(nil)
        settingsController?.window?.makeKeyAndOrderFront(nil)
    }

    private func updateSettings() {
        guard let settingsController else { return }
        let displays = [SettingsChoice(id: "built-in", title: "Built-in display (preferred)"),
                        SettingsChoice(id: "active", title: "Follow active display")] +
            DisplayChoice.choices(for: NSScreen.screens).map { SettingsChoice(id: $0.id, title: $0.name) }
        let clocks = packs.flatMap { pack in pack.clocks.map { SettingsChoice(id: pack.id + "/" + $0.id, title: pack.name + " · " + $0.name) } }
        let widgets = packs.flatMap { pack in (pack.widgets ?? []).map { SettingsChoice(id: pack.id + "/" + $0.id, title: pack.name + " · " + $0.name) } }
        let themes = packs.flatMap { pack in (pack.themes ?? []).map { (SettingsChoice(id: pack.id + "/" + $0.id, title: pack.name + " · " + $0.name), $0) } }
        let description = geometry.map { "\(selectedScreenName)\nCompact height: \(Int($0.height)) pt · Notch gap: \(Int($0.gap)) pt · Automatic sizing" } ?? "Waiting for display geometry"
        settingsController.update(preferences: preferences, displays: displays, clocks: clocks,
            widgets: widgets, themes: themes, selectedClock: selectedKey,
            selectedWidget: selectedWidgetKey, geometryDescription: description)
    }

    private func observeEvents() {
        globalPointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluateHover() }
        }
        localPointerMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            MainActor.assumeIsolated { self?.evaluateHover() }
            return event
        }
        panel.acceptsMouseMovedEvents = true
        let center = NotificationCenter.default
        for name in [Notification.Name.NSSystemClockDidChange,
                     .NSSystemTimeZoneDidChange, NSLocale.currentLocaleDidChangeNotification] {
            center.addObserver(self, selector: #selector(systemChanged), name: name, object: nil)
        }
        center.addObserver(self, selector: #selector(scheduleGeometryUpdate),
                           name: NSApplication.didChangeScreenParametersNotification, object: nil)
        for name in [NSWindow.didChangeScreenNotification, NSWindow.didChangeBackingPropertiesNotification] {
            center.addObserver(self, selector: #selector(scheduleGeometryUpdate), name: name, object: panel)
        }
        center.addObserver(self, selector: #selector(scheduleGeometryUpdate),
                           name: UserDefaults.didChangeNotification, object: nil)
        presentationObservation = NSApp.observe(\.currentSystemPresentationOptions) { [weak self] _, _ in
            Task { @MainActor [weak self] in self?.scheduleGeometryUpdate() }
        }
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(scheduleGeometryUpdate),
                              name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(scheduleGeometryUpdate),
                              name: NSWorkspace.didActivateApplicationNotification, object: nil)
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification] {
            workspace.addObserver(self, selector: #selector(suspendClock), name: name, object: nil)
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            workspace.addObserver(self, selector: #selector(resumeClock), name: name, object: nil)
        }
    }

    @objc private func scheduleGeometryUpdate() {
        guard !geometryUpdatePending else { return }
        geometryUpdatePending = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.geometryUpdatePending = false
            self.reconcileScreen()
        }
    }

    private func reconcileScreen() {
        let screens = NSScreen.screens
        let choices = DisplayChoice.choices(for: screens)
        guard let index = DisplayChoice.selectedIndex(preference: preferences.display, choices: choices,
            activeID: NSScreen.main.map { DisplayChoice.id(for: $0) }) else { return }
        let screen = screens[index]
        selectedScreenName = choices[index].name
        guard let updated = geometryResolver.geometry(for: screen, statusWindow: statusItem.button?.window) else {
            panel.orderOut(nil)
            geometry = nil
            return
        }
        guard geometry != updated else { return }
        geometry = updated
        content.barHeight = updated.height
        content.notchGap = updated.gap
        applyFrame(animated: false)
        if visible && !sleeping { panel.orderFrontRegardless() }
        updateSettings()
    }

    private func applyFrame(animated: Bool) {
        guard let geometry else { return }
        let frame = mix(geometry.frame(expanded: false), geometry.frame(expanded: true, expandedHeight: content.expandedHeight), content.progress)
        if panel.frame != frame { panel.setFrame(frame, display: true) }
        content.needsLayout = true
    }

    private func pointerIsInside(at position: NSPoint? = nil) -> Bool {
        guard visible, !sleeping, panel.isVisible, let geometry else { return false }
        let point = position ?? NSEvent.mouseLocation
        if point.y > geometry.screenFrame.maxY - geometry.height && abs(point.x - geometry.center) < geometry.gap / 2 { return false }
        guard panel.frame.contains(point) else { return false }
        return content.containsInteractionPoint(content.convert(panel.convertPoint(fromScreen: point), from: nil))
    }

    private func evaluateHover(at position: NSPoint? = nil) {
        guard !menuTracking else { return }
        if pointerIsInside(at: position) {
            hoverExit?.invalidate(); hoverExit = nil
            setExpanded(true)
        } else if expanded && hoverExit == nil {
            // Brief exit grace lets the pointer cross the growing outline without flicker.
            let timer = Timer(timeInterval: 0.12, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.hoverExit = nil
                    if !self.pointerIsInside() && !self.menuTracking { self.setExpanded(false) }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            hoverExit = timer
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menuTracking = true
        hoverExit?.invalidate(); hoverExit = nil
    }
    func menuDidClose(_ menu: NSMenu) {
        menuTracking = false
        evaluateHover()
    }

    private func setExpanded(_ value: Bool, animated: Bool = true) {
        guard expanded != value || !animated else { return }
        expanded = value
        content.setExpanded(value, animated: animated)
        let reduced = preferences.reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        morph.move(to: value ? 1 : 0, animated: animated && !reduced)
        refresh()
    }

    // The deterministic probe can exercise both endpoints without manufacturing pointer events.
    @objc func toggleExpanded() { setExpanded(!expanded) }

    @objc private func toggleVisible() {
        visible.toggle()
        if visible { reconcileScreen(); if geometry != nil { panel.orderFrontRegardless() }; refresh() }
        else {
            hoverExit?.invalidate(); hoverExit = nil
            setExpanded(false, animated: false)
            panel.orderOut(nil); timer?.invalidate(); timer = nil; usageClient.cancel()
        }
    }

    private func refresh() {
        timer?.invalidate()
        timer = nil
        guard visible && !sleeping else { return }
        reconcileScreen()
        let now = Date()
        refreshUsage(at: now)
        content.update(date: now)
        let next = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / (expanded ? 1 : 60)) + 1) * (expanded ? 1 : 60))
        let timer = Timer(fireAt: next, interval: 0, target: self, selector: #selector(tick), userInfo: nil, repeats: false)
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func tick() { refresh() }
    @objc private func systemChanged() { content.configureFormatters(); reconcileScreen(); refresh() }
    @objc private func suspendClock() {
        sleeping = true
        hoverExit?.invalidate(); hoverExit = nil
        setExpanded(false, animated: false)
        timer?.invalidate(); timer = nil; usageClient.cancel()
    }
    @objc private func resumeClock() { sleeping = false; systemChanged() }
    @objc private func quit() { NSApp.terminate(nil) }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        presentationObservation = nil
        hoverExit?.invalidate()
        morph.stop()
        if let globalPointerMonitor { NSEvent.removeMonitor(globalPointerMonitor) }
        if let localPointerMonitor { NSEvent.removeMonitor(localPointerMonitor) }
        usageClient.cancel()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func renderPreviews(to directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for isExpanded in [false, true] {
            expanded = isExpanded
            content.setExpanded(isExpanded, animated: false)
            applyFrame(animated: false)
            content.frame = NSRect(origin: .zero, size: panel.frame.size)
            content.layoutSubtreeIfNeeded()
            content.displayIfNeeded()
            guard let bitmap = content.bitmapImageRepForCachingDisplay(in: content.bounds) else { continue }
            content.cacheDisplay(in: content.bounds, to: bitmap)
            let name = isExpanded ? "expanded-clock.png" : "compact-clock.png"
            try? bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent(name))
        }
    }
}
