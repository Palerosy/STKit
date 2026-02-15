import XCTest
@testable import STTXT

final class STTXTTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(STTXT.version, "0.1.0")
    }
}
