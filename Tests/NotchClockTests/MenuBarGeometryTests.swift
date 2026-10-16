import AppKit
import XCTest
@testable import NotchClock

final class MenuBarGeometryTests: XCTestCase {
    private func metrics(height: CGFloat, safeTop: CGFloat = 0, scale: CGFloat = 2,
                         origin: NSPoint = .zero) -> MenuBarMetrics {
        let frame = NSRect(origin: origin, size: NSSize(width: 1512, height: 982))
        return MenuBarMetrics(frame: frame,
            visibleFrame: NSRect(x: frame.minX, y: frame.minY + 60, width: frame.width,
                                 height: frame.height - height - 60),
            scale: scale, safeTop: safeTop,
            leftArea: safeTop > 0 ? NSRect(x: frame.minX, y: frame.maxY - safeTop, width: 650, height: safeTop) : nil,
            rightArea: safeTop > 0 ? NSRect(x: frame.minX + 862, y: frame.maxY - safeTop, width: 650, height: safeTop) : nil,
            fallbackHeight: 22)
    }

    func testMeasuredHeightOverridesGlobalThicknessAcrossDisplays() throws {
        for height: CGFloat in [22, 24, 28, 32, 38, 48] {
            let geometry = try XCTUnwrap(metrics(height: height).resolve())
            XCTAssertEqual(geometry.height, height)
            XCTAssertEqual(geometry.gap, 0)
            XCTAssertEqual(geometry.frame(expanded: false).maxY, 982)
        }
    }

    func testNotchGapAndHeightKeepBothWingsOutsideCutout() throws {
        let geometry = try XCTUnwrap(metrics(height: 38, safeTop: 38).resolve())
        XCTAssertEqual(geometry.height, 38)
        XCTAssertEqual(geometry.gap, 212)
        XCTAssertEqual(geometry.center, 756)
        XCTAssertEqual(geometry.center - geometry.gap / 2, 650)
        XCTAssertEqual(geometry.center + geometry.gap / 2, 862)
        XCTAssertEqual(metrics(height: 48, safeTop: 38).resolve()?.height, 38)
        XCTAssertEqual(metrics(height: 24, safeTop: 38).resolve()?.height, 24)
    }

    func testHiddenBarUsesPreviousMeasurementThenNativeFallbacks() {
        var hidden = metrics(height: 0)
        XCTAssertEqual(hidden.resolve(previousHeight: 28)?.height, 28)
        hidden.statusItemHeight = 24
        XCTAssertEqual(hidden.resolve()?.height, 24)
        hidden.statusItemHeight = nil
        XCTAssertEqual(hidden.resolve()?.height, 22)
        XCTAssertEqual(metrics(height: 0, safeTop: 38).resolve()?.height, 38)
        XCTAssertEqual(metrics(height: 0.5).resolve(previousHeight: 28)?.height, 28)
    }

    func testPositionAndExpansionUseDisplayCoordinatesAndKeepTopFixed() throws {
        for origin in [NSPoint(x: -1600, y: 200), NSPoint(x: 400, y: 1200)] {
            let geometry = try XCTUnwrap(metrics(height: 28, origin: origin).resolve())
            let compact = geometry.frame(expanded: false)
            let expanded = geometry.frame(expanded: true)
            XCTAssertEqual(compact.height, 28)
            XCTAssertEqual(expanded.height, 418)
            XCTAssertEqual(compact.maxY, geometry.screenFrame.maxY)
            XCTAssertEqual(expanded.maxY, compact.maxY)
            XCTAssertEqual(compact.midX, expanded.midX)
            XCTAssertEqual(geometry.frame(expanded: false), compact)
        }
    }

    func testScalingRoundsDownWithinAvailableBandAndDockIsExcluded() {
        XCTAssertEqual(metrics(height: 27.8, scale: 1).resolve()?.height, 27)
        XCTAssertEqual(metrics(height: 27.8, scale: 2).resolve()?.height, 27.5)
        XCTAssertEqual(metrics(height: 24).resolve()?.height, 24) // Fixture also reserves 60 points for the Dock.
    }

    func testMissingCutoutGeometryDoesNotPlaceControlsAcrossNotch() {
        let source = metrics(height: 38, safeTop: 38)
        let incomplete = MenuBarMetrics(frame: source.frame, visibleFrame: source.visibleFrame,
            scale: 2, safeTop: 38, leftArea: nil, rightArea: nil, fallbackHeight: 22)
        XCTAssertNil(incomplete.resolve())
    }
}
