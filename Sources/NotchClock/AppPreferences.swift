import AppKit

struct AppPreferences: Equatable {
    var display = "built-in"
    var visualFamily = VisualFamily.wavy
    var theme = "dev.kavrin.originals/original"
    var uses24HourTime = true
    var reduceMotion = false
    var startExpanded = false

    init(defaults: UserDefaults = .standard) {
        display = defaults.string(forKey: "preferredDisplay") ?? display
        visualFamily = defaults.string(forKey: "visualFamily").flatMap(VisualFamily.init(rawValue:)) ?? .wavy
        theme = defaults.string(forKey: "selectedTheme") ?? theme
        uses24HourTime = defaults.object(forKey: "uses24HourTime") as? Bool ?? true
        reduceMotion = defaults.bool(forKey: "reduceClockMotion")
        startExpanded = defaults.bool(forKey: "startExpanded")
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(display, forKey: "preferredDisplay")
        defaults.set(visualFamily.rawValue, forKey: "visualFamily")
        defaults.set(theme, forKey: "selectedTheme")
        defaults.set(uses24HourTime, forKey: "uses24HourTime")
        defaults.set(reduceMotion, forKey: "reduceClockMotion")
        defaults.set(startExpanded, forKey: "startExpanded")
    }
}

struct DisplayChoice: Equatable {
    let id: String
    let name: String
    let builtIn: Bool

    static func selectedIndex(preference: String, choices: [DisplayChoice], activeID: String?) -> Int? {
        if let exact = choices.firstIndex(where: { $0.id == preference }) { return exact }
        if preference == "active", let active = choices.firstIndex(where: { $0.id == activeID }) { return active }
        // Keep a disconnected preference saved; use the laptop until that display returns.
        return choices.firstIndex(where: \.builtIn) ?? choices.indices.first
    }

    @MainActor static func id(for screen: NSScreen) -> String {
        let number = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(number)?.takeRetainedValue() else { return "display-\(number)" }
        return CFUUIDCreateString(nil, uuid) as String
    }

    @MainActor static func choices(for screens: [NSScreen]) -> [DisplayChoice] {
        screens.map { screen in
            let number = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let builtIn = CGDisplayIsBuiltin(number) != 0
            return DisplayChoice(id: id(for: screen), name: screen.localizedName + (builtIn ? " · Built-in" : " · External"), builtIn: builtIn)
        }
    }
}
