import AppKit
import XCTest
@testable import NotchClock

final class MorphMotionTests: XCTestCase {
    func testReversalPreservesPositionAndSettlesAtBothEndpoints() {
        var motion = MorphMotion()
        motion.target = 1
        for _ in 0..<10 { motion.advance(by: 1 / 60) }
        XCTAssertGreaterThan(motion.value, 0)
        XCTAssertLessThan(motion.value, 1)
        let position = motion.value
        let velocity = motion.velocity
        motion.target = 0
        XCTAssertEqual(motion.value, position)
        XCTAssertEqual(motion.velocity, velocity)
        for _ in 0..<120 { motion.advance(by: 1 / 60) }
        XCTAssertTrue(motion.isAtRest)
        XCTAssertEqual(motion.value, 0)
        motion.target = 1
        for _ in 0..<120 { motion.advance(by: 1 / 60) }
        XCTAssertTrue(motion.isAtRest)
        XCTAssertEqual(motion.value, 1)
    }

    func testFrameInterpolationKeepsTopAnchorOnOffsetDisplay() {
        let geometry = BarGeometry(screenFrame: NSRect(x: -1920, y: 479, width: 1920, height: 1080),
                                   center: -960, gap: 0, height: 25)
        let paper = geometry.frame(expanded: true, expandedHeight: 217)
        XCTAssertEqual(paper.height, 217)
        XCTAssertEqual(paper.maxY, geometry.screenFrame.maxY)
        for p in stride(from: CGFloat(0), through: 1, by: 0.05) {
            let frame = mix(geometry.frame(expanded: false), geometry.frame(expanded: true), p)
            XCTAssertEqual(frame.maxY, geometry.screenFrame.maxY, accuracy: 0.001)
            XCTAssertEqual(frame.midX, geometry.center, accuracy: 0.001)
        }
    }
}

@MainActor
final class MorphViewTests: XCTestCase {
    func testPaperCutHasOneConnectedFrameAndOneHoverRegionThroughoutMorph() throws {
        let theme = try XCTUnwrap(ThemeDesign.originals.first { $0.id == "paper-cut" })
        for height in [CGFloat(24), 32, 38] {
            for gap in [CGFloat(0), 185] {
                let host = ClockContentView(frame: .zero)
                host.barHeight = height
                host.notchGap = gap
                host.select(ClockPack.builtIn.clocks[1])
                host.selectWidget(WidgetDesign.originals[1])
                host.applyTheme(theme)
                let identities = host.subviews.map(ObjectIdentifier.init)
                for p in [CGFloat(0), 0.25, 0.5, 0.75, 1, 0.5, 0] {
                    host.frame = NSRect(x: 0, y: 0, width: mix(gap + 224, 640, p), height: mix(height, height + 390, p))
                    host.setProgress(p)
                    host.layoutSubtreeIfNeeded()
                    XCTAssertEqual(host.subviews.map(ObjectIdentifier.init), identities)
                    XCTAssertEqual(host.paperFrame.minY, 0)
                    XCTAssertLessThanOrEqual(host.paperFrame.maxY, host.bounds.maxY)
                    for item in host.subviews.compactMap({ $0 as? NotchItemView }) {
                        XCTAssertTrue(item.sharesPaperFrame)
                        XCTAssertTrue(host.paperFrame.contains(item.frame))
                        XCTAssertTrue(host.containsInteractionPoint(NSPoint(x: item.frame.midX, y: item.frame.midY)))
                    }
                    if gap > 0 { XCTAssertFalse(host.containsInteractionPoint(NSPoint(x: host.bounds.midX, y: height / 2))) }
                    if p > 0.5 { XCTAssertTrue(host.containsInteractionPoint(NSPoint(x: host.bounds.midX, y: host.paperFrame.midY))) }
                    XCTAssertFalse(host.containsInteractionPoint(NSPoint(x: 0, y: host.bounds.maxY + 1)))
                }
            }
        }
    }

    func testSameObjectsAndThemeSurviveEntireMorphAndReplacement() throws {
        _ = NSApplication.shared
        let host = ClockContentView(frame: NSRect(x: 0, y: 0, width: 640, height: 422))
        host.barHeight = 32; host.notchGap = 185
        host.select(ClockPack.builtIn.clocks[1])
        let theme = ThemeDesign.originals[2]
        host.applyTheme(theme)
        let identities = host.subviews.map(ObjectIdentifier.init)
        for progress in [CGFloat(0), 0.25, 0.5, 0.75, 1, 0.5, 0] {
            host.setProgress(progress)
            host.layoutSubtreeIfNeeded()
            XCTAssertEqual(host.subviews.map(ObjectIdentifier.init), identities)
            XCTAssertEqual(host.subviews.count, 2)
            for item in host.subviews.compactMap({ $0 as? NotchItemView }) {
                XCTAssertEqual(item.expansionProgress, progress)
                XCTAssertEqual(item.palette.design, theme)
                XCTAssertEqual(item.accent, ThemePalette(theme).clockAccent)
            }
        }
        host.setProgress(0.4)
        host.selectWidget(WidgetDesign.originals[1])
        let usage = try XCTUnwrap(host.subviews.compactMap { $0 as? UsageWidgetView }.first)
        XCTAssertEqual(usage.expansionProgress, 0.4)
        XCTAssertEqual(usage.palette.design, theme)
        XCTAssertNil(host.hitTest(NSPoint(x: host.bounds.midX, y: 16)))
    }
}
