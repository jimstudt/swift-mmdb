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

    func testCountryLookup() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country-Test", withExtension: "mmdb", subdirectory: "test-data") else {
            XCTFail("Unable to find test GeoLite2-Country-Test.mmdb file.")
            return
        }
        
        guard let db = try? GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }
        
        XCTAssertEqual(db.metadata.databaseType, "GeoLite2-Country")
        
        guard case let .value(core) = db.search(address: "2.125.160.216") else {
            XCTFail("Failed to search some EU address")
            return
        }
        core.dump()

        guard case let .value(somewhere) = db.search(address: "2001:270::0") else {
            XCTFail("Failed to search a KR ipv6 address")
            return
        }
        somewhere.dump()
        
        XCTAssertEqual(try db.countryCode(address: "2001:270::0"), "KR")

    }

    func testCountryPerformanceIPv4() throws {
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country-Test", withExtension: "mmdb", subdirectory: "test-data") else {
            XCTFail("Unable to find test GeoLite2-Country-Test.mmdb file.")
            return
        }

        guard let db = try? GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        let hosts = [ "2.125.160.216",
                      "50.114.0.0",
                      "67.43.156.0",
                      "81.2.69.142",
                      "81.2.69.144",
                      "81.2.69.160",
                      "81.2.69.192",
                      "89.160.20.112",
                      "89.160.20.128",
                      "111.235.160.0",
                      "202.196.224.0",
                      "216.160.83.56",
                      "217.65.48.0" ]

        self.measure {
            for addr in hosts {
                guard case .value(_) = db.search(address: addr) else {
                    XCTFail("Failed to search \(addr)")
                    return
                }
            }
        }
        

    }

    func testCountryPerformanceIPv6() throws {
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country-Test", withExtension: "mmdb", subdirectory: "test-data") else {
            XCTFail("Unable to find test GeoLite2-Country-Test.mmdb file.")
            return
        }

        guard let db = try? GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        let hosts = [ "2001:2e0::1",
                      "2001:2e8::2",
                      "2001:2f0::3",
                      "2001:2f8::4",
                      "2a02:cf40::5",
                      "2a02:cf80::6",
                      "2a02:cfc0::7",
                      "2a02:d000::8",
                      "2a02:d040::9",
                      "2a02:d080::10"]
        self.measure {
            for addr in hosts {
                guard case .value(_) = db.search(address: addr) else {
                    XCTFail("Failed to search \(addr)")
                    return
                }
            }
        }

    }

}
