import XCTest
@testable import CBarcodeScanner

final class CBarcodeReaderTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CBarcodeScanner().text, "Hello, World!")
    }
}
