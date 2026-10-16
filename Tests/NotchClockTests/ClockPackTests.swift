import XCTest
@testable import NotchClock

final class ClockPackTests: XCTestCase {
    private func manifest(id: String = "test.collection", clocks: String? = nil, version: Int = 1) -> Data {
        let entries = clocks ?? "{\"id\":\"digital\",\"name\":\"Digital\",\"renderer\":\"capsuleDigital\",\"accent\":\"C93D33\"}"
        return Data("{\"schemaVersion\":\(version),\"id\":\"\(id)\",\"name\":\"Test\",\"clocks\":[\(entries)]}".utf8)
    }

    func testRejectsUnsupportedOrUnsafeManifests() {
        XCTAssertThrowsError(try ClockPack.decode(manifest(version: 2)))
        XCTAssertThrowsError(try ClockPack.decode(manifest(id: "../escape")))
        XCTAssertThrowsError(try ClockPack.decode(manifest(id: ClockPack.builtIn.id)))
        XCTAssertThrowsError(try ClockPack.decode(Data(repeating: 32, count: 65_537)))
        let entry = "{\"id\":\"same\",\"name\":\"Clock\",\"renderer\":\"wavyAnalog\",\"accent\":\"C93D33\"}"
        XCTAssertThrowsError(try ClockPack.decode(manifest(clocks: entry + "," + entry)))
        XCTAssertThrowsError(try ClockPack.decode(manifest(clocks: entry.replacingOccurrences(of: "wavyAnalog", with: "executable"))))
        XCTAssertThrowsError(try ClockPack.decode(manifest(clocks: entry.replacingOccurrences(of: "C93D33", with: "invalid"))))
    }

    func testInstallReloadAndDuplicatePreservesOriginal() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source.json")
        try manifest().write(to: source)
        let store = ClockPackStore(directory: root.appendingPathComponent("installed"))
        let pack = try store.install(manifest: source)
        XCTAssertEqual(store.installed().packs, [pack])
        XCTAssertThrowsError(try store.install(manifest: source))
        XCTAssertEqual(store.installed().packs, [pack])
        try Data("broken".utf8).write(to: store.directory.appendingPathComponent("broken.json"))
        XCTAssertEqual(store.installed().packs, [pack])
        XCTAssertEqual(store.installed().warnings.count, 1)
    }

    func testRejectsSymlinkManifest() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source.json")
        let link = root.appendingPathComponent("link.json")
        try manifest().write(to: source)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: source)
        XCTAssertThrowsError(try ClockPackStore(directory: root.appendingPathComponent("installed")).install(manifest: link))
    }
}
