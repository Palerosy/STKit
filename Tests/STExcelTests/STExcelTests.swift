import XCTest
@testable import STExcel

final class STExcelTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(STExcel.version, "0.1.0")
    }

    func testColumnLetter() {
        XCTAssertEqual(STExcelSheet.columnLetter(0), "A")
        XCTAssertEqual(STExcelSheet.columnLetter(25), "Z")
        XCTAssertEqual(STExcelSheet.columnLetter(26), "AA")
    }

    func testBlankDocument() {
        let doc = STExcelDocument(title: "Test", rows: 10, columns: 5)
        XCTAssertEqual(doc.sheets.count, 1)
        XCTAssertEqual(doc.activeSheet.rowCount, 10)
        XCTAssertEqual(doc.activeSheet.columnCount, 5)
    }
}
