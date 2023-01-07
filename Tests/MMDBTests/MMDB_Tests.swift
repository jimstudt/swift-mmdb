import XCTest
@testable import MMDB

let someIPv4Addresses = [ "2.125.160.216",
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

final class MMDB_Tests: XCTestCase {
    func readAllAcceptErrors(forResource name: String, withExtension ext: String = "mmdb", subdirectory subpath: String) throws {
        guard let fileURL = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: subpath) else {
            XCTFail("Could not find resource \(name) with extension \(ext) in subpath \(subpath).")
            return
        }
        let mmdb = try MMDB(from: fileURL)
        
        try mmdb.enumerate{ bits, count in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            switch mmdb.search(value: bits, bits: count) {
            case .value(let v):
                v.dump()
            case .notFound:
                print("\(hex)/\(count)not found")
            case .partial(_):
                XCTFail("unexpected partial")
            case .failed(let m):
                print("READ FAILURE: \(m)")
            }
        }
    }

    func readAll(forResource: String, withExtension: String = "mmdb", subdirectory: String) throws {
        guard let fileURL = Bundle.module.url(forResource: forResource, withExtension: withExtension, subdirectory: subdirectory) else {
            XCTFail("Failed to open MMDB")
            return
        }
        let mmdb = try MMDB(from: fileURL)
        
        try mmdb.enumerate{ bits, count in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to search \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testGeoIP2CountryTest() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let fileURL = Bundle.module.url(forResource: "GeoIP2-Country-Test", withExtension: "mmdb", subdirectory: "test-data") else {
            XCTFail("Unable to find test GeoIP2-Country-Test.mmdb file.")
            return
        }
        
        guard let mmdb = try? MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }
        
        guard case let .value(norsk) = mmdb.search(value: 0x2a02f30000000000, bits: 64) else {
            XCTFail("Failed to search for some random norwegian site")
            return
        }
        norsk.dump()
        
        // 192.0.2.0 should be usable as a test network according to RFC 5737. It probably isn't located.
        guard case .notFound = mmdb.search( starting: mmdb.ipv4Root, value: 0xc0000200 << 32, bits: 32) else {
            XCTFail("Failed to get a 'notfound' for RFC 5737 Test-Net-1")
            return
        }
    }
    
    func testIPv4_24() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv4-24", subdirectory: "test-data")
    }
    
    func testIPv4_28() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv4-28", subdirectory: "test-data")
    }

    func testIPv4_32() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv4-32", subdirectory: "test-data")
    }

    func testIPv6_24() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv6-24", subdirectory: "test-data")
    }
    
    func testIPv6_28() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv6-28", subdirectory: "test-data")
    }

    func testIPv6_32() throws {
        try readAll(forResource: "MaxMind-DB-test-ipv6-32", subdirectory: "test-data")
    }

    func testIP_24() throws {
        try readAll(forResource: "MaxMind-DB-test-mixed-24", subdirectory: "test-data")
    }
    
    func testIP_28() throws {
        try readAll(forResource: "MaxMind-DB-test-mixed-28", subdirectory: "test-data")
    }

    func testIP_32() throws {
        try readAll(forResource: "MaxMind-DB-test-mixed-32", subdirectory: "test-data")
    }

    func testNested() throws {
        try readAll(forResource: "MaxMind-DB-test-nested", subdirectory: "test-data")
    }

    func testPointerDecoder() throws {
        try readAll(forResource: "MaxMind-DB-test-pointer-decoder", subdirectory: "test-data")
    }

    func testDecoder() throws {
        try readAll(forResource: "MaxMind-DB-test-decoder", subdirectory: "test-data")
    }

    func testMetadataPointers() throws {
        try readAll(forResource: "MaxMind-DB-test-metadata-pointers", subdirectory: "test-data")
    }

    func testStringValueEntries() throws {
        try readAll(forResource: "MaxMind-DB-string-value-entries", subdirectory: "test-data")
    }

    func testNoIPv4SearchTree() throws {
        try readAll(forResource: "MaxMind-DB-no-ipv4-search-tree", subdirectory: "test-data")
    }

    func testBrokenPointers24() throws {
        try readAllAcceptErrors(forResource: "MaxMind-DB-test-broken-pointers-24", subdirectory: "test-data")
    }

    func testBrokenSearchTree() throws {
        try readAllAcceptErrors(forResource: "MaxMind-DB-test-broken-search-tree-24", subdirectory: "test-data")
    }

    func testGeoIP2AnonymousIP() throws {
        try readAll(forResource: "GeoIP2-Anonymous-IP-Test", subdirectory: "test-data")
    }

    func testGeoIP2CityTest() throws {
        try readAll(forResource: "GeoIP2-City-Test", subdirectory: "test-data")
    }

    func testGeoIP2ConnectionTypeTest() throws {
        try readAll(forResource: "GeoIP2-Connection-Type-Test", subdirectory: "test-data")
    }

    func testGeoIP2DensityIncomeTest() throws {
        try readAll(forResource: "GeoIP2-DensityIncome-Test", subdirectory: "test-data")
    }

    func testGeoIP2DomainTest() throws {
        try readAll(forResource: "GeoIP2-Domain-Test", subdirectory: "test-data")
    }

    func testGeoIP2EnterpriseTest() throws {
        try readAll(forResource: "GeoIP2-Enterprise-Test", subdirectory: "test-data")
    }

    func testGeoIP2ISPTest() throws {
        try readAll(forResource: "GeoIP2-ISP-Test", subdirectory: "test-data")
    }

    func testGeoIP2PrecisionEnterpriseTest() throws {
        try readAll(forResource: "GeoIP2-Precision-Enterprise-Test", subdirectory: "test-data")
    }

    func testGeoIP2StaticIPScoreTest() throws {
        try readAll(forResource: "GeoIP2-Static-IP-Score-Test", subdirectory: "test-data")
    }

    func testGeoIP2UserCountTest() throws {
        try readAll(forResource: "GeoIP2-User-Count-Test", subdirectory: "test-data")
    }

    func testGeoLite2ASNTest() throws {
        try readAll(forResource: "GeoLite2-ASN-Test", subdirectory: "test-data")
    }

    func testGeoLite2CityTest() throws {
        try readAll(forResource: "GeoLite2-City-Test", subdirectory: "test-data")
    }

    func testGeoLite2CountryTest() throws {
        try readAll(forResource: "GeoLite2-Country-Test", subdirectory: "test-data")
    }

    func testGeoIP2CityTestBrokenDoubleFormat() throws {
        try readAllAcceptErrors(forResource: "GeoIP2-City-Test-Broken-Double-Format", subdirectory: "test-data")
    }

    func testGeoIP2CityTestInvalidNodeCount() throws {
        guard let fileURL = Bundle.module.url(forResource: "GeoIP2-City-Test-Invalid-Node-Count", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = try? MMDB(from: fileURL) else {
            return
        }
        XCTFail("Opened MMDB with insane node count: \(mmdb.metadata.nodeCount)")
    }

    func testCyclicDataStructure() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "cyclic-data-structure", subdirectory: "bad-data/maxminddb-golang"))
    }
    
    func testInvalidBytesLength() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "invalid-bytes-length", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testInvalidDataRecordOffset() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "invalid-data-record-offset", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testInvalidMapKeyLength() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "invalid-map-key-length", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testInvalidStringLength() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "invalid-string-length", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testMetadataIsAnUInt128() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "metadata-is-an-uint128", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testUnexpectedBytes() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "unexpected-bytes", subdirectory: "bad-data/maxminddb-golang"))
    }

    func testBadUnicodeInMapKey() throws {
        try readAllAcceptErrors(forResource: "bad-unicode-in-map-key", subdirectory: "bad-data/maxminddb-python")
    }

    func testOffsetIntegerOverflow() throws {
        XCTAssertThrowsError(try readAllAcceptErrors(forResource: "libmaxminddb-offset-integer-overflow", subdirectory: "bad-data/libmaxminddb"))
    }
}
