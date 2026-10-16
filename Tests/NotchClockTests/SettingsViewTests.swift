import AppKit
import XCTest
@testable import NotchClock

@MainActor
final class SettingsViewTests: XCTestCase {
    func testExplicitHourFormatAndThemeSurviveClockReplacement() throws {
        _ = NSApplication.shared
        let host = ClockContentView(frame: NSRect(x: 0, y: 0, width: 640, height: 422))
        let date = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 15, minute: 30)))
        host.uses24HourTime = false
        let theme = ThemeDesign.originals[1]
        host.applyTheme(theme)
        host.update(date: date)
        let analog = try XCTUnwrap(host.subviews.first { $0 is CompactClockView })
        XCTAssertTrue(analog.accessibilityLabel()?.contains("3:30 PM") == true)
        host.select(ClockPack.builtIn.clocks[1])
        host.update(date: date)
        let digital = try XCTUnwrap(host.subviews.compactMap { $0 as? DigitalClockView }.first)
        XCTAssertEqual(digital.palette.design, theme)
        XCTAssertFalse(digital.uses24HourTime)
        XCTAssertTrue(digital.accessibilityLabel()?.contains("3:30 PM") == true)
        host.uses24HourTime = true
        host.update(date: date)
        XCTAssertTrue(digital.accessibilityLabel()?.contains("15:30") == true)
    }
}
