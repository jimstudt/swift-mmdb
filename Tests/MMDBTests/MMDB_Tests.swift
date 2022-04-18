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
        
        guard case let .partial(zero64) = mmdb.search(value: 0, bits: 64),
              case let .partial(zero96) = mmdb.search(starting: zero64, value: 0, bits: 32) else {
            XCTFail("Failed to search zero96 partial")
            return
        }
        
        guard case let .value(core) = mmdb.search(starting: zero96, value: 0xc7d9af01 << 32, bits: 32) else {
            XCTFail("Failed to search the old core.federated.com server")
            return
        }
        core.dump()
        
        // 192.0.2.0 should be usable as a test network according to RFC 5737. It probably isn't located.
        guard case .notFound = mmdb.search( starting: zero96, value: 0xc0000200 << 32, bits: 32) else {
            XCTFail("Failed to get a 'notfound' for RFC 5737 Test-Net-1")
            return
        }
    }
}
