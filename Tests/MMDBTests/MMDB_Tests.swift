import XCTest
@testable import MMDB

final class MMDB_Tests: XCTestCase {
    func testGeoIP2CountryTest() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let fileURL = Bundle.module.url(forResource: "GeoIP2-Country-Test", withExtension: "mmdb", subdirectory: "test-data") else {
            XCTFail("Unable to find test GeoIP2-Country-Test.mmdb file.")
            return
        }
        
        guard let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }
        
        guard case let .partial(zero64) = mmdb.search(value: 0, bits: 64),
              case let .partial(zero96) = mmdb.search(starting: zero64, value: 0, bits: 32) else {
            XCTFail("Failed to search zero96 partial")
            return
        }
        
        guard case let .value(norsk) = mmdb.search(value: 0x2a02f30000000000, bits: 64) else {
            XCTFail("Failed to search the some random norwegian site")
            return
        }
        norsk.dump()
        
        // 192.0.2.0 should be usable as a test network according to RFC 5737. It probably isn't located.
        guard case .notFound = mmdb.search( starting: zero96, value: 0xc0000200 << 32, bits: 32) else {
            XCTFail("Failed to get a 'notfound' for RFC 5737 Test-Net-1")
            return
        }
    }
}
