import XCTest
@testable import STDOCX

final class STDOCXTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(STDOCX.version, "0.1.0")
    }
}
