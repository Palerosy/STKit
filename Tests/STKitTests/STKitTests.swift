import XCTest
@testable import STKit

final class STKitTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(STKit.version, "0.1.0")
    }

    func testDocumentStats() {
        let stats = STDocumentStats(from: "Hello world.\nThis is a test.")
        XCTAssertEqual(stats.words, 6)
        XCTAssertEqual(stats.paragraphs, 2)
        XCTAssertEqual(stats.lines, 2)
    }

    func testLicenseNotActivated() {
        XCTAssertFalse(STKit.isLicensed)
    }
}
