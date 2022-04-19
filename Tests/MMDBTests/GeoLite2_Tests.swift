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

    func testCountryPerformanceIPv4() throws {
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "TestData") else {
            XCTFail("Unable to find test GeoLite2-Country.mmdb file.")
            return
        }
        
        guard let db = GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        let ntp4Servers = [ "132.163.96.5", "132.163.97.5", "128.138.141.177", "200.160.7.186", "217.31.202.100",
                           "83.92.2.24", "193.93.164.193", "189.136.149.62", "89.175.20.7", "212.111.203.225"]
        self.measure {
            for addr in ntp4Servers {
                guard case .value(_) = db.search(address: addr) else {
                    XCTFail("Failed to search \(addr)")
                    return
                }
            }
        }
        

    }

    func testCountryPerformanceIPv6() throws {
        guard let fileURL = Bundle.module.url(forResource: "GeoLite2-Country", withExtension: "mmdb", subdirectory: "TestData") else {
            XCTFail("Unable to find test GeoLite2-Country.mmdb file.")
            return
        }
        
        guard let db = GeoLite2CountryDatabase(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        let ntp6Servers = [ "2001:67c:21c:123::1", "2a04:6480:101::221", "2001:12ff:0:7::197", "2001:470:1f07:d::5", "2001:4b20::beef:1:16",
                           "2001:720:1410:101f::15", "2001:67c:6c:58::77", "2001:2f8:29:100::fff3", "2a01:3f7:2:1::1", "2604:4080:111d:2010:2ee3:98d7:48eb:60b4"]
        self.measure {
            for addr in ntp6Servers {
                guard case .value(_) = db.search(address: addr) else {
                    XCTFail("Failed to search \(addr)")
                    return
                }
            }
        }

    }

}
