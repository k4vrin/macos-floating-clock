import XCTest
@testable import NotchClock

final class ClockModelTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testHandsUseTheSameInstantAndIncludeMinuteProgress() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 3, minute: 30))!
        let angles = HandAngles(date: date, calendar: calendar)
        XCTAssertEqual(angles.hour, 7 * .pi / 12, accuracy: 0.00001)
        XCTAssertEqual(angles.minute, .pi, accuracy: 0.00001)
    }

    func testMidnightAndNoonShareAnalogPosition() {
        for hour in [0, 12] {
            let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: hour))!
            let angles = HandAngles(date: date, calendar: calendar)
            XCTAssertEqual(angles.hour, 0)
            XCTAssertEqual(angles.minute, 0)
        }
    }

}
