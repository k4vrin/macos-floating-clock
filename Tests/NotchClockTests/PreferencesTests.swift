import XCTest
@testable import NotchClock

final class PreferencesTests: XCTestCase {
    func testPreferencesRoundTripAndDefaults() {
        let name = "test.settings." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        var settings = AppPreferences(defaults: defaults)
        XCTAssertEqual(settings.display, "built-in")
        XCTAssertTrue(settings.uses24HourTime)
        XCTAssertFalse(settings.startExpanded)
        settings.visualFamily = .counter
        settings.display = "external-uuid"
        settings.theme = "test.collection/blue"
        settings.uses24HourTime = false
        settings.reduceMotion = true
        settings.startExpanded = true
        settings.save(to: defaults)
        XCTAssertEqual(AppPreferences(defaults: defaults), settings)
    }

    func testUnknownFamilyPreferenceFallsBackToWavy() {
        let name = "test.family." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("unsupported", forKey: "visualFamily")
        XCTAssertEqual(AppPreferences(defaults: defaults).visualFamily, .wavy)
    }

    func testThemeFamilyRecommendationIsOptionalAndValidated() throws {
        var theme = ThemeDesign.originals[0]
        theme.family = .counter
        XCTAssertEqual(try JSONDecoder().decode(ThemeDesign.self, from: JSONEncoder().encode(theme)), theme)
        let encoded = String(data: try JSONEncoder().encode(theme), encoding: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ThemeDesign.self,
            from: Data(encoded.replacingOccurrences(of: "counter", with: "unknown").utf8)))
        theme.family = nil
        XCTAssertNil(try JSONDecoder().decode(ThemeDesign.self, from: JSONEncoder().encode(theme)).family)
    }

    @MainActor
    func testPaperCutComponentColorsSurviveWidgetReplacementAndPackRoundTrip() throws {
        let theme = try XCTUnwrap(ThemeDesign.originals.first { $0.id == "paper-cut" })
        let pack = ClockPack(schemaVersion: 1, id: "test.paper", name: "Paper", clocks: [], widgets: nil, themes: [theme])
        XCTAssertEqual(try ClockPack.decode(JSONEncoder().encode(pack)), pack)
        let host = ClockContentView(frame: .zero)
        host.applyTheme(theme)
        let calendar = try XCTUnwrap(host.subviews.compactMap { $0 as? DateWidgetView }.first)
        XCTAssertEqual(calendar.palette.surface, ThemePalette.color("F1C34F"))
        host.selectWidget(WidgetDesign.originals[1])
        let usage = try XCTUnwrap(host.subviews.compactMap { $0 as? UsageWidgetView }.first)
        XCTAssertEqual(usage.palette.surface, ThemePalette.color("164865"))
        XCTAssertTrue(usage.palette.isPaperCut)
        host.applyTheme(ThemeDesign.originals[0])
        XCTAssertFalse(usage.palette.isPaperCut)
        XCTAssertEqual(usage.palette.surface, ThemePalette().surface)
        let encoded = try JSONEncoder().encode(pack)
        let invalid = String(decoding: encoded, as: UTF8.self).replacingOccurrences(of: "F1C34F", with: "invalid")
        XCTAssertThrowsError(try ClockPack.decode(Data(invalid.utf8)))
    }

    func testDisplaySelectionAndDisconnectedFallback() {
        let choices = [DisplayChoice(id: "external", name: "Desk", builtIn: false),
                       DisplayChoice(id: "laptop", name: "Laptop", builtIn: true)]
        XCTAssertEqual(DisplayChoice.selectedIndex(preference: "built-in", choices: choices, activeID: "external"), 1)
        XCTAssertEqual(DisplayChoice.selectedIndex(preference: "external", choices: choices, activeID: "laptop"), 0)
        XCTAssertEqual(DisplayChoice.selectedIndex(preference: "active", choices: choices, activeID: "external"), 0)
        XCTAssertEqual(DisplayChoice.selectedIndex(preference: "disconnected", choices: choices, activeID: "external"), 1)
        XCTAssertEqual(DisplayChoice.selectedIndex(preference: "built-in", choices: [choices[0]], activeID: nil), 0)
        XCTAssertNil(DisplayChoice.selectedIndex(preference: "built-in", choices: [], activeID: nil))
    }

    func testThemeOnlyPackAndLegacyCompatibility() throws {
        let pack = ClockPack(schemaVersion: 1, id: "test.themes", name: "Themes", clocks: [], widgets: nil,
                             themes: [ThemeDesign.originals[1]])
        XCTAssertEqual(try ClockPack.decode(JSONEncoder().encode(pack)), pack)
        let legacy = Data(#"{"schemaVersion":1,"id":"test.legacy","name":"Legacy","clocks":[{"id":"clock","name":"Clock","renderer":"wavyAnalog","accent":"C93D33"}]}"#.utf8)
        XCTAssertNil(try ClockPack.decode(legacy).themes)
        var duplicate = pack
        duplicate.themes = [ThemeDesign.originals[1], ThemeDesign.originals[1]]
        XCTAssertThrowsError(try ClockPack.decode(JSONEncoder().encode(duplicate)))
        let valid = String(data: try JSONEncoder().encode(pack), encoding: .utf8)!
        XCTAssertThrowsError(try ClockPack.decode(Data(valid.replacingOccurrences(of: "142836", with: "invalid").utf8)))
    }
}
