import XCTest
@testable import NotchClock

final class CodexUsageClientTests: XCTestCase {
    private func executable(_ body: String) throws -> URL {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("wavy-provider-" + UUID().uuidString)
        try ("#!/bin/sh\n" + body).write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: file.path)
        return file
    }

    @MainActor
    func testHandshakeReturnsSnapshotAndClosesSession() async throws {
        let file = try executable("""
        read initialize
        printf '%s\\n' '{"id":1,"result":{}}'
        read initialized
        read limits
        printf '%s\\n' '{"id":2,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":12,"windowDurationMins":300}}}}'
        read closed
        """)
        defer { try? FileManager.default.removeItem(at: file) }
        let client = CodexUsageClient(executableURL: file)
        let result: Result<UsageSnapshot, Error> = await withCheckedContinuation { continuation in
            client.fetch { continuation.resume(returning: $0) }
        }
        XCTAssertEqual(try result.get().windows.first?.usedPercent, 12)
        XCTAssertFalse(client.isRunning)
    }

    @MainActor
    func testTimeoutStopsSilentProvider() async throws {
        let file = try executable("read request\nread more\n")
        defer { try? FileManager.default.removeItem(at: file) }
        let client = CodexUsageClient(executableURL: file, requestTimeout: .milliseconds(100))
        let result: Result<UsageSnapshot, Error> = await withCheckedContinuation { continuation in
            client.fetch { continuation.resume(returning: $0) }
        }
        if case .success = result { XCTFail("Silent provider should time out") }
        XCTAssertFalse(client.isRunning)
    }

    @MainActor
    func testCancelClosesSessionWithoutDeliveringLateCallback() throws {
        let file = try executable("read request\nread more\n")
        defer { try? FileManager.default.removeItem(at: file) }
        let client = CodexUsageClient(executableURL: file)
        client.fetch { _ in XCTFail("Cancelled request should not deliver a callback") }
        XCTAssertTrue(client.isRunning)
        client.cancel()
        XCTAssertFalse(client.isRunning)
    }
}
