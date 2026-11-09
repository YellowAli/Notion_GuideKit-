import XCTest
import SwiftUI
@testable import GuideKit

final class TooltipPlacementTests: XCTestCase {
    private let size = CGSize(width: 400, height: 800)
    private let safeArea = EdgeInsets(top: 60, leading: 0, bottom: 30, trailing: 0)
    private let margin: CGFloat = 16
    private var safeTop: CGFloat { safeArea.top + margin }
    private var safeBottom: CGFloat { size.height - safeArea.bottom - margin }

    private func place(hole: CGRect?, size: CGSize? = nil) -> TooltipPlacement {
        TooltipPlacement.compute(hole: hole, size: size ?? self.size, safeArea: safeArea, gap: 12, margin: margin)
    }

    private func assertInsideSafeArea(_ p: TooltipPlacement, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(p.minY, safeTop, line: line)
        XCTAssertLessThanOrEqual(p.maxY, safeBottom, line: line)
    }

    func testRoomBelowPlacesRegionUnderHole() {
        let p = place(hole: CGRect(x: 0, y: 100, width: 50, height: 40))
        XCTAssertEqual(p, TooltipPlacement(minY: 152, maxY: safeBottom, alignment: .top))
    }

    func testRoomAbovePlacesRegionOverHole() {
        let p = place(hole: CGRect(x: 0, y: 650, width: 50, height: 40))
        XCTAssertEqual(p, TooltipPlacement(minY: safeTop, maxY: 638, alignment: .bottom))
    }

    func testLittleRoomAboveKeepsMinimumHeightInsideSafeArea() {
        // A tall hole near the bottom: above wins, but only just has space.
        let p = place(hole: CGRect(x: 0, y: 100, width: 50, height: 690))
        XCTAssertEqual(p.alignment, .bottom)
        assertInsideSafeArea(p)
        XCTAssertEqual(p.maxY - p.minY, TooltipPlacement.minimumHeight)
    }

    func testLittleRoomBelowKeepsMinimumHeightInsideSafeArea() {
        // A tall hole near the top: below wins, but only just has space.
        let p = place(hole: CGRect(x: 0, y: 10, width: 50, height: 700))
        XCTAssertEqual(p.alignment, .top)
        assertInsideSafeArea(p)
        XCTAssertEqual(p.maxY - p.minY, TooltipPlacement.minimumHeight)
    }

    func testCenteredRegionIsCappedToSafeArea() {
        let p = place(hole: nil)
        XCTAssertEqual(p, TooltipPlacement(minY: safeTop, maxY: safeBottom, alignment: .center))
    }

    func testZeroRoomOnBothSidesStaysInsideSafeArea() {
        let p = place(hole: CGRect(origin: .zero, size: size))
        assertInsideSafeArea(p)
        XCTAssertEqual(p.maxY - p.minY, TooltipPlacement.minimumHeight)
    }

    func testOffscreenHoleStaysInsideSafeArea() {
        assertInsideSafeArea(place(hole: CGRect(x: 0, y: 2000, width: 50, height: 40)))
        assertInsideSafeArea(place(hole: CGRect(x: 0, y: -2000, width: 50, height: 40)))
    }

    func testScreenShorterThanMinimumUsesAllSafeHeight() {
        let short = CGSize(width: 400, height: 200)
        let p = place(hole: CGRect(x: 0, y: 90, width: 50, height: 20), size: short)
        XCTAssertEqual(p.minY, safeTop)
        XCTAssertEqual(p.maxY, short.height - safeArea.bottom - margin)
    }
}
