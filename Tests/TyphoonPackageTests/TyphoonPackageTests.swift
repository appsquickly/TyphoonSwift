import XCTest
@testable import TyphoonPackage

class TyphoonPackageTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(TyphoonPackage().description, "Typhoon Swift Package v 0.0.1")
    }


    static var allTests : [(String, (TyphoonPackageTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }

    func testThatFileDefinitionCreatesProperly() {
        //given
        let fileName = "testFile.py"

        //when
         let fileDefinition = FileDefinition(fileName: fileName)

         //then
         XCTAssertEqual(fileDefinition.fileName, fileName)
    }

    func testThatAssemblyDefinitionCreatesWithNameProperly() {
        //given
        let name = "TestAssembly"

        //when
        let assembly = AssemblyDefinition(withName: name)

        //then
        XCTAssertEqual(assembly.name, name) 
    }
}
