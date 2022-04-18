import Foundation
public class MMDB {
    enum FieldType : UInt8 {
        case pointer = 1
        case string = 2
        case double = 3
        case bytes = 4
        case uint16 = 5
        case uint32 = 6
        case map = 7
        case int32 = 8
        case uint64 = 9
        case uint128 = 10
        case array = 11
        case dataCacheContainer = 12
        case endMarker = 13
        case boolean = 14
        case float = 15
    }
    indirect enum Value {
        case string(String)
        case map( [String:Value])
        case uint( UInt)
        case int( Int)
        case double( Double)
        case bytes( [UInt8] )
        case array( [Value])
    }
    
    struct Store {
        private let size : Int
        private let db : UnsafeRawPointer
        private let bytes : UnsafePointer<UInt8>
        
        public init( data: Data) {
            size = data.count
            
            db = data.withUnsafeBytes{ (_ body: (UnsafeRawBufferPointer)) -> UnsafeRawPointer in
                let mdb = UnsafeMutableRawPointer.allocate(byteCount: body.count, alignment: 8)
                mdb.copyMemory(from: body.baseAddress!, byteCount: body.count)
                return UnsafeRawPointer( mdb)
            }
            bytes = db.bindMemory(to: UInt8.self, capacity: size)
        }
        
        func locateMetadata( ) -> Int? {
            // This is "\xab\xcd\xefMaxMind.com" per the spec, but that is invalid UTF8, so we are kind of screwed there.
            let marker : [UInt8] = [ 0xab, 0xcd, 0xef, 0x4D, 0x61, 0x78, 0x4D, 0x69, 0x6E, 0x64, 0x2E, 0x63, 0x6F, 0x6D ]
            
            // Look back from the end of the file until we find the last match.
            for i in (0 ..< size - marker.count).reversed()  {
                if bytes[i] != marker.first! { continue }
                if marker.indices.allSatisfy({ bytes[i + $0] == marker[$0]}) {
                    return i + marker.count
                }
            }

            return nil
        }

        func readValue( pointer: inout Int) -> Value? {
            let controlByte = bytes[pointer]
            pointer += 1
            
            let top3 = controlByte >> 5
            let payloadSize0 = controlByte & 0x1f
            let fieldType : FieldType
            let payloadSize : Int

            switch top3 {
            case 0:
                guard let ft = FieldType(rawValue: bytes[pointer] + 7) else {
                    // invalid field type
                    return nil
                }
                pointer += 1
                fieldType = ft
            default:
                guard let ft = FieldType(rawValue: top3) else {
                    return nil   // bad field type, really shouldn't be able to happen
                }
                fieldType = ft
            }
            
            switch payloadSize0 {
            case 29:
                let p1 = bytes[pointer]
                pointer += 1
                payloadSize = 29 + Int(p1)
            case 30:
                let p1 = bytes[pointer]
                pointer += 1
                let p2 = bytes[pointer]
                pointer += 1
                payloadSize = 285 + 256 * Int(p1) + Int(p2)
            case 31:
                let p1 = bytes[pointer]
                pointer += 1
                let p2 = bytes[pointer]
                pointer += 1
                let p3 = bytes[pointer]
                pointer += 1
                payloadSize = 65821 + 65536 * Int(p1) + 256 * Int(p2) + Int(p3)
            default:
                payloadSize = Int(payloadSize0)
            }
            
            switch fieldType {
            case .pointer:
                fatalError("Field type \(fieldType) not supported")
            case .string:
                let u = (0..<payloadSize).map{ bytes[pointer + $0]}
                pointer += payloadSize
                guard let s = String(bytes: u, encoding: .utf8) else {
                    return nil
                }
                return .string(s)
            case .double:
                let v : UnsafePointer<Double> = .init( OpaquePointer( db.advanced(by: pointer)))
                pointer += 8
                return .double(v.pointee)
            case .bytes:
                let v : [UInt8] = (0 ..< payloadSize).map{ bytes[ pointer + $0]}
                pointer += payloadSize
                return .bytes( v)
            case .uint16, .uint32, .uint64:
                var r : UInt = 0
                for i in 0 ..< payloadSize {
                    r = 256 * r + UInt( bytes[pointer + i])
                }
                pointer += payloadSize
                return .uint( r)
            case .map:
                var result : [String:Value] = [:]
                for _ in 0 ..< payloadSize {
                    guard case let .string(key) = readValue(pointer: &pointer) else {
                        return nil   // key must be a string
                    }
                    guard let val = readValue(pointer: &pointer) else {
                        return nil
                    }
                    result[key] = val
                }
                return .map(result)
            case .int32:
                fatalError("Field type \(fieldType) not supported")
            case .uint128:
                fatalError("Field type \(fieldType) not supported")
            case .array:
                var result : [Value] = []
                for _ in 0 ..< payloadSize {
                    guard let val = readValue(pointer: &pointer) else {
                        return nil
                    }
                    result.append(val)
                }
                return .array(result)
            case .dataCacheContainer:
                fatalError("Field type \(fieldType) not supported")
            case .endMarker:
                fatalError("Field type \(fieldType) not supported")
            case .boolean:
                fatalError("Field type \(fieldType) not supported")
            case .float:
                fatalError("Field type \(fieldType) not supported")
            }
        }

    }
    
    private let store : Store
    let majorVersion : UInt
    let minorVersion : UInt
    let epoch : UInt
    let ipVersion : UInt
    let recordSize : UInt
    let nodeCount : UInt
    let databaseType : String
    
    private let searchTreeSize : UInt
    
    public private(set) var text = "Hello, World!"

    public init?( data: Data) {
        store = Store(data: data)
        
        guard let offs = store.locateMetadata() else {
            return nil
        }

        var p = offs
        guard case let .map(metadata) = store.readValue(pointer: &p) else {
            print("Unable to read metadata")
            return nil
        }
        
        guard case let .uint(major) = metadata["binary_format_major_version"],
              case let .uint(minor) = metadata["binary_format_minor_version"] else {
            print("no major and minor version")
            return nil
        }
        
        if major < 2 {
            print("not major version 2")
            return nil
        }
        
        majorVersion = major
        minorVersion = minor
        
        guard case let .uint(epoch) = metadata["build_epoch"],
              case let .uint(ipVersion) = metadata["ip_version"],
              case let .uint(recordSize) = metadata["record_size"],
              case let .uint(nodeCount) = metadata["node_count"],
              case let .string(databaseType) = metadata["database_type"] else {
            print("Missing some metadata")
            return nil
        }
        
        self.epoch = epoch
        self.ipVersion = ipVersion
        self.recordSize = recordSize
        self.nodeCount = nodeCount
        self.databaseType = databaseType
        
        searchTreeSize = ( ( recordSize * 2 ) / 8 ) * nodeCount
    }
    
    public convenience init?( from: URL) {
        guard let d = try? Data( contentsOf: from) else {
            return nil
        }
        self.init( data: d)
    }
    
}
