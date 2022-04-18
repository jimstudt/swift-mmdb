//
//  GeoLite2_Tests.swift
//  
//
//  Created by Jim Studt on 4/18/22.
//

import XCTest
@testable import MMDB

class GeoLite2_Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "TestData") else {
            XCTFail("Unable to find test GeoLite2-Country.mmdb file.")
            return
        }
        
        guard let db = GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }
        
        XCTAssertEqual(db.databaseType, "GeoLite2-Country")
        
        guard case let .value(core) = db.search(address: "199.217.175.1") else {
            XCTFail("Failed to search the old core.federated.com server")
            return
        }
        core.dump()

        guard case let .value(somewhere) = db.search(address: "2001:0b28:f23f:f005:0000:0000:0000:000a") else {
            XCTFail("Failed to search the ipv6 address")
            return
        }
        somewhere.dump()
        
        XCTAssertEqual( db.countryCode(address: "2001:0b28:f23f:f005:0000:0000:0000:000a"), "AG")

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
