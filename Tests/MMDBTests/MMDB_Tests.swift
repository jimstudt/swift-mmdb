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
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv4-24", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }
    
    func testIPv4_28() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv4-28", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testIPv4_32() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv4-32", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testIPv6_24() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv6-24", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }
    
    func testIPv6_28() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv6-28", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testIPv6_32() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-ipv6-32", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testIP_24() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-mixed-24", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }
    
    func testIP_28() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-mixed-28", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testIP_32() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-mixed-32", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testNested() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-nested", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testPointerDecoder() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-pointer-decoder", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testDecoder() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-decoder", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testMetadataPointers() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-metadata-pointers", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testStringValueEntries() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-string-value-entries", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testNoIPv4SearchTree() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-no-ipv4-search-tree", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
            let hex = bits.reduce("") { $0 +  String(format:"%08x", $1) }
            print( "\(hex)/\(count)" )
            
            guard case let .value(v) = mmdb.search(value: bits, bits: count) else {
                XCTFail("failed to searc \(hex)/\(count)")
                return
            }
            v.dump()
        }
    }

    func testBrokenPointers24() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-broken-pointers-24", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
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

    func testBrokenSearchTree() throws {
        guard let fileURL = Bundle.module.url(forResource: "MaxMind-DB-test-broken-search-tree-24", withExtension: "mmdb", subdirectory: "test-data"),
              let mmdb = MMDB(from: fileURL) else {
            XCTFail("Failed to open MMDB")
            return
        }

        mmdb.enumerate{ (bits:[UInt32], count: Int) in
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

}

