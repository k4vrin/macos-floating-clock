import XCTest
@testable import NotchClock

final class UsageModelTests: XCTestCase {
    func testCodexUsesCodexBucketAndPreservesZero() throws {
        let data = Data(#"{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":300}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":0,"windowDurationMins":300,"resetsAt":2000000000},"secondary":{"usedPercent":45,"windowDurationMins":10080}},"other":{"primary":{"usedPercent":88,"windowDurationMins":300}}}}"#.utf8)
        let snapshot = try UsageSnapshot.codex(result: data)
        XCTAssertEqual(snapshot.windows.map(\.usedPercent), [0, 45])
        XCTAssertEqual(snapshot.windows.first?.resetsAt, Date(timeIntervalSince1970: 2000000000))
        let other = Data(#"{"rateLimitsByLimitId":{"other":{"primary":{"usedPercent":88,"windowDurationMins":300}}}}"#.utf8)
        XCTAssertTrue(try UsageSnapshot.codex(result: other).windows.isEmpty)
    }

    func testBankedResetCountUsesSummaryAndPreservesUnknownAndZero() throws {
        for (raw, expected) in [("3", 3), ("0", 0), ("-1", nil), ("1.5", nil), ("true", nil), ("\"3\"", nil), ("null", nil)] as [(String, Int?)] {
            let data = Data("{\"rateLimitResetCredits\":{\"availableCount\":\(raw),\"credits\":[]}}".utf8)
            XCTAssertEqual(try UsageSnapshot.codex(result: data).bankedResetCount, expected)
        }
        XCTAssertNil(try UsageSnapshot.codex(result: Data("{}".utf8)).bankedResetCount)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = UsageCache(directory: directory)
        let snapshot = UsageSnapshot(provider: .codex, observedAt: Date(), windows: [], bankedResetCount: 4)
        try cache.save(snapshot)
        XCTAssertEqual(cache.load(.codex)?.bankedResetCount, 4)
        let legacy = Data("{\"provider\":\"codex\",\"observedAt\":0,\"windows\":[]}".utf8)
        XCTAssertNil(try JSONDecoder().decode(UsageSnapshot.self, from: legacy).bankedResetCount)
        try cache.save(UsageSnapshot(provider: .codex, observedAt: Date(), windows: [], bankedResetCount: -1))
        XCTAssertNil(cache.load(.codex))
    }

    func testClaudeMissingWindowsAreUnknownAndInvalidValuesAreRejected() throws {
        XCTAssertTrue(try UsageSnapshot.claude(statusLine: Data("{}".utf8)).windows.isEmpty)
        let data = Data(#"{"rate_limits":{"five_hour":{"used_percentage":100,"resets_at":2000000000},"seven_day":{"used_percentage":-1}},"cost":{"total_cost_usd":999},"context_window":{"used_percentage":88}}"#.utf8)
        let snapshot = try UsageSnapshot.claude(statusLine: data)
        XCTAssertEqual(snapshot.windows.map(\.usedPercent), [100])
        XCTAssertEqual(snapshot.windows.map(\.durationMinutes), [300])
        XCTAssertThrowsError(try UsageSnapshot.claude(statusLine: Data(repeating: 0, count: 1_048_577)))
    }

    func testStaleAndExpiredDataNeverBecomesZeroUsage() {
        let now = Date(timeIntervalSince1970: 2000000000)
        let snapshot = UsageSnapshot(provider: .claude, observedAt: now.addingTimeInterval(-301), windows: [
            UsageWindow(usedPercent: 80, durationMinutes: 300, resetsAt: now)
        ])
        XCTAssertTrue(snapshot.isStale(at: now))
        XCTAssertTrue(snapshot.windows[0].isExpired(at: now))
        XCTAssertEqual(snapshot.windows[0].usedPercent, 80)
    }

    func testPartialWindowsKeepTheirIdentityAndResetLabels() {
        let now = Date(timeIntervalSince1970: 2000000000)
        let weekly = UsageWindow(usedPercent: 45, durationMinutes: 10080, resetsAt: now.addingTimeInterval(90000))
        let snapshot = UsageSnapshot(provider: .codex, observedAt: now, windows: [weekly])
        XCTAssertNil(snapshot.displayWindows[0])
        XCTAssertEqual(snapshot.displayWindows[1], weekly)
        XCTAssertEqual(weekly.shortLabel, "7d")
        XCTAssertEqual(weekly.resetDescription(at: now), "1d 1h")
        XCTAssertEqual(UsageWindow(usedPercent: 1, durationMinutes: 15, resetsAt: nil).shortLabel, "15m")
    }

    func testCacheRoundTripAndCorruptIsolation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = UsageCache(directory: directory)
        let snapshot = UsageSnapshot(provider: .codex, observedAt: Date(), windows: [])
        try cache.save(snapshot)
        XCTAssertEqual(cache.load(.codex), snapshot)
        XCTAssertNil(cache.load(.claude))
        try Data("broken".utf8).write(to: directory.appendingPathComponent("claude.json"))
        XCTAssertNil(cache.load(.claude))
        XCTAssertEqual(cache.load(.codex), snapshot)
    }

    func testWidgetOnlyPackAndLegacyClockPackCompatibility() throws {
        let widgetOnly = Data(#"{"schemaVersion":1,"id":"studio.widgets","name":"Widgets","clocks":[],"widgets":[{"id":"date","name":"Date","renderer":"flipDate","accent":"237CA3"},{"id":"usage","name":"AI","renderer":"aiUsage","accent":"9BAF84"}]}"#.utf8)
        XCTAssertEqual(try ClockPack.decode(widgetOnly).widgets?.count, 2)
        XCTAssertThrowsError(try ClockPack.decode(Data(String(decoding: widgetOnly, as: UTF8.self).replacingOccurrences(of: "aiUsage", with: "script").utf8)))
        XCTAssertThrowsError(try ClockPack.decode(Data(String(decoding: widgetOnly, as: UTF8.self).replacingOccurrences(of: "\"id\":\"usage\"", with: "\"id\":\"date\"").utf8)))
        let legacy = Data(#"{"schemaVersion":1,"id":"studio.clocks","name":"Clocks","clocks":[{"id":"clock","name":"Clock","renderer":"wavyAnalog","accent":"237CA3"}]}"#.utf8)
        XCTAssertNil(try ClockPack.decode(legacy).widgets)
    }
}
