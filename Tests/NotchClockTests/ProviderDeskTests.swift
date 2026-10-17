import AppKit
import XCTest
@testable import NotchClock

@MainActor
final class ProviderDeskTests: XCTestCase {
    func testSelectedProviderKeepsFiveHourAndWeeklySlotsIsolated() throws {
        let date = Date(timeIntervalSince1970: 2_000_000_000)
        let view = UsageWidgetView(compact: true)
        view.date = date
        let weekly = UsageWindow(usedPercent: 73, durationMinutes: 10080, resetsAt: date.addingTimeInterval(3600))
        view.snapshots = [
            .codex: UsageSnapshot(provider: .codex, observedAt: date, windows: [weekly]),
            .claude: UsageSnapshot(provider: .claude, observedAt: date, windows: [
                UsageWindow(usedPercent: 12, durationMinutes: 300, resetsAt: date.addingTimeInterval(60))
            ])
        ]
        XCTAssertNil(view.windowRows[0])
        XCTAssertEqual(view.windowRows[1], weekly)
        view.updateAccessibility()
        XCTAssertTrue(view.accessibilityLabel()?.contains("5-hour usage unavailable") == true)
        XCTAssertTrue(view.accessibilityLabel()?.contains("73 percent used") == true)
        view.provider = .claude
        XCTAssertEqual(view.windowRows[0]?.usedPercent, 12)
        XCTAssertNil(view.windowRows[1])
        XCTAssertFalse(view.accessibilityLabel()?.contains("73 percent") == true)
        view.date = date.addingTimeInterval(61)
        view.updateAccessibility()
        XCTAssertTrue(view.accessibilityLabel()?.contains("expired") == true)
        XCTAssertFalse(view.accessibilityLabel()?.contains("12 percent used") == true)
    }

    func testPackProviderSelectionAndLegacyDefault() throws {
        let legacy = Data(#"{"schemaVersion":1,"id":"test.desks","name":"Desks","clocks":[],"widgets":[{"id":"usage","name":"Usage","renderer":"aiUsage","accent":"C93D33"}]}"#.utf8)
        let design = try XCTUnwrap(ClockPack.decode(legacy).widgets?.first)
        XCTAssertEqual(design.usageProvider, .codex)
        let explicit = Data(String(decoding: legacy, as: UTF8.self).replacingOccurrences(of: "\"accent\":", with: "\"provider\":\"claude\",\"accent\":").utf8)
        let claude = try XCTUnwrap(ClockPack.decode(explicit).widgets?.first)
        let view = try XCTUnwrap(WidgetViewFactory.make(claude, compact: true) as? UsageWidgetView)
        XCTAssertEqual(view.provider, .claude)
        let invalid = Data(String(decoding: explicit, as: UTF8.self).replacingOccurrences(of: "\"claude\"", with: "\"other\"").utf8)
        XCTAssertThrowsError(try ClockPack.decode(invalid))
    }
}
