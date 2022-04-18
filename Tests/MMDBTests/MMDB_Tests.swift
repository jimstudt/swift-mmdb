import XCTest
@testable import MMDB

final class MMDB_Tests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "TestData") else {
            XCTFail("Unable to find test GeoLite2-Country.mmdb file.")
            return
        }
        
        guard let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }
        
        XCTAssertEqual( mmdb.text, "Hello, World!")
    }
}
