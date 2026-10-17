import XCTest
@testable import NotchClock

final class WavyNumeralTests: XCTestCase {
    func testEverySupportedGlyphHasFiniteNormalizedInkBounds() throws {
        for character in "0123456789:%" {
            let path = try XCTUnwrap(WavyNumerals.path(for: character))
            let bounds = path.boundingBoxOfPath
            XCTAssertFalse(path.isEmpty)
            XCTAssertTrue(bounds.minX.isFinite && bounds.minY.isFinite)
            XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(bounds))
            XCTAssertGreaterThan(bounds.height, 0)
        }
        XCTAssertNil(WavyNumerals.path(for: "A"))
    }

    func testClockAndUsageStringsFitCompactAndExpandedAreas() {
        for size in [CGSize(width: 47, height: 19), CGSize(width: 210, height: 84)] {
            let rect = CGRect(origin: CGPoint(x: 10, y: 12), size: size)
            for text in ["11:11", "08:08", "100%", "00:00", "23:59"] {
                let placements = WavyNumerals.layout(text, in: rect)
                XCTAssertEqual(placements.map(\.character), Array(text))
                for glyph in placements {
                    XCTAssertGreaterThan(glyph.frame.height, 0)
                    XCTAssertGreaterThanOrEqual(glyph.frame.minX, rect.minX - 0.0001)
                    XCTAssertLessThanOrEqual(glyph.frame.maxX, rect.maxX + 0.0001)
                    XCTAssertGreaterThanOrEqual(glyph.frame.minY, rect.minY - 0.0001)
                    XCTAssertLessThanOrEqual(glyph.frame.maxY, rect.maxY + 0.0001)
                }
            }
        }
    }

    func testInvalidInputsDoNotPartiallyRender() {
        let rect = CGRect(x: 0, y: 0, width: 84, height: 32)
        for value in ["", "12 AM", "١٢", "12x"] { XCTAssertTrue(WavyNumerals.layout(value, in: rect).isEmpty) }
        XCTAssertTrue(WavyNumerals.layout("12", in: .zero).isEmpty)
    }
}
