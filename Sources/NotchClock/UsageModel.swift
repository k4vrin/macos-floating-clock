import Foundation

enum UsageProvider: String, Codable, CaseIterable, Sendable {
    case codex, claude
    var title: String { rawValue.capitalized }
}

struct UsageWindow: Codable, Equatable, Sendable {
    let usedPercent: Double
    let durationMinutes: Int
    let resetsAt: Date?

    var shortLabel: String {
        if durationMinutes % 1440 == 0 { return "\(durationMinutes / 1440)d" }
        if durationMinutes % 60 == 0 { return "\(durationMinutes / 60)h" }
        return "\(durationMinutes)m"
    }

    func resetDescription(at date: Date) -> String? {
        guard let resetsAt else { return nil }
        let minutes = Int(ceil(resetsAt.timeIntervalSince(date) / 60))
        guard minutes > 0 else { return "awaiting reset data" }
        if minutes >= 1440 { return "\(minutes / 1440)d \(minutes % 1440 / 60)h" }
        if minutes >= 60 { return "\(minutes / 60)h \(minutes % 60)m" }
        return "\(minutes)m"
    }

    func isExpired(at date: Date) -> Bool { resetsAt.map { $0 <= date } ?? false }
}

struct UsageSnapshot: Codable, Equatable, Sendable {
    let provider: UsageProvider
    let observedAt: Date
    let windows: [UsageWindow]

    var displayWindows: [UsageWindow?] {
        [windows.first(where: { $0.durationMinutes < 1440 }), windows.first(where: { $0.durationMinutes >= 1440 })]
    }

    func isStale(at date: Date) -> Bool { date.timeIntervalSince(observedAt) > 300 || observedAt > date.addingTimeInterval(60) }

    static func codex(result: Data, observedAt: Date = Date()) throws -> UsageSnapshot {
        let root = try JSONSerialization.jsonObject(with: result) as? [String: Any] ?? [:]
        let buckets = root["rateLimitsByLimitId"] as? [String: Any]
        // Never substitute another model's quota for the user's Codex bucket.
        let bucket: [String: Any]?
        if let buckets { bucket = buckets["codex"] as? [String: Any] }
        else {
            let legacy = root["rateLimits"] as? [String: Any]
            let id = legacy?["limitId"] as? String
            bucket = id == nil || id == "codex" ? legacy : nil
        }
        let windows = ["primary", "secondary"].compactMap { key -> UsageWindow? in
            guard let window = bucket?[key] as? [String: Any] else { return nil }
            return parseWindow(window, percentKey: "usedPercent", duration: window["windowDurationMins"] as? Int)
        }
        return UsageSnapshot(provider: .codex, observedAt: observedAt, windows: windows)
    }

    static func claude(statusLine: Data, observedAt: Date = Date()) throws -> UsageSnapshot {
        guard statusLine.count <= 1_048_576 else { throw UsageError.invalid("Status-line input exceeds 1 MiB.") }
        let root = try JSONSerialization.jsonObject(with: statusLine) as? [String: Any] ?? [:]
        let limits = root["rate_limits"] as? [String: Any] ?? [:]
        let windows = [("five_hour", 300), ("seven_day", 10080)].compactMap { key, duration -> UsageWindow? in
            guard let window = limits[key] as? [String: Any] else { return nil }
            return parseWindow(window, percentKey: "used_percentage", duration: duration, resetKey: "resets_at")
        }
        return UsageSnapshot(provider: .claude, observedAt: observedAt, windows: windows)
    }

    private static func parseWindow(_ value: [String: Any], percentKey: String, duration: Int?, resetKey: String = "resetsAt") -> UsageWindow? {
        guard let percent = value[percentKey] as? Double, percent.isFinite, (0...100).contains(percent),
              let duration, (1...525600).contains(duration) else { return nil }
        let reset = (value[resetKey] as? Double).flatMap { $0.isFinite && $0 > 0 ? Date(timeIntervalSince1970: $0) : nil }
        return UsageWindow(usedPercent: percent, durationMinutes: duration, resetsAt: reset)
    }
}

enum UsageError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

struct UsageCache: Sendable {
    let directory: URL
    static let standard = UsageCache(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("WavyClock/Usage", isDirectory: true))

    func save(_ snapshot: UsageSnapshot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(snapshot).write(to: directory.appendingPathComponent(snapshot.provider.rawValue + ".json"), options: .atomic)
    }

    func load(_ provider: UsageProvider) -> UsageSnapshot? {
        let file = directory.appendingPathComponent(provider.rawValue + ".json")
        guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 16_384,
              let data = try? Data(contentsOf: file), let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data),
              snapshot.provider == provider, snapshot.windows.count <= 2,
              snapshot.windows.allSatisfy({ $0.usedPercent.isFinite && (0...100).contains($0.usedPercent) && (1...525600).contains($0.durationMinutes) }) else { return nil }
        return snapshot
    }
}
