import XCTest
@testable import TyphoonPackage

class TyphoonPackageTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(TyphoonPackage().text, "Hello, World!")
    }


    static var allTests : [(String, (TyphoonPackageTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
