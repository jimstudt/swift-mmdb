import Foundation
public class MMDB {
    
    /// The data field type tag read from the MMDB file as given in *MaxMind DB File Format Specification 2.0*
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
        
        
        /// Scan a Value once the FieldType is known.
        /// - Parameters:
        ///   - bytes: The raw bytes, must be able to subscript from `pointer` to `pointer + size`.
        ///   - size: The number of bytes to process.
        /// - Returns: Read a `MMDB.Value` from a block of bytes. Does not work for `.map` and `.array`, only
        ///   the simple types.
        func scan( bytes: UnsafePointer<UInt8>, size: Int) -> Value? {
            switch self {
            case .pointer:
                fatalError("Field type '\(self)' not supported")
            case .string:
                let u = (0..<size).map{ bytes[$0]}
                guard let s = String(bytes: u, encoding: .utf8) else {
                    return nil
                }
                return .string(s)
            case .double:
                let v : UnsafePointer<Double> = .init( OpaquePointer( bytes))
                return .double(v.pointee)
            case .bytes:
                let v : [UInt8] = (0 ..< size).map{ bytes[$0]}
                return .bytes( v)
            case .uint16:
                var r : UInt16 = 0
                for i in 0 ..< size {
                    r = (r << 8) | UInt16( bytes[i])
                }
                return .uint16( r)
            case .uint32:
                var r : UInt32 = 0
                for i in 0 ..< size {
                    r = (r << 8) | UInt32( bytes[i])
                }
                return .uint32( r)
            case .uint64:
                var r : UInt64 = 0
                for i in 0 ..< size {
                    r = (r << 8) | UInt64( bytes[i])
                }
                return .uint64( r)
            case .int32:
                fatalError("Field type '\(self)' not supported")
            case .uint128:
                fatalError("Field type '\(self)' not supported")
            case .dataCacheContainer:
                fatalError("Field type '\(self)' not supported")
            case .endMarker:
                fatalError("Field type '\(self)' not supported")
            case .boolean:
                fatalError("Field type '\(self)' not supported")
            case .float:
                fatalError("Field type '\(self)' not supported")
                
            //
            // `map` and `array` need to be able to recursively call into the
            // Store's readValue function. They have to be handled at a higher
            // level.
            //
            case .map:
                fatalError("Field type '.map' can not be scanned by FieldType")
            case .array:
                fatalError("Field type '.array' can not be scanned by FieldType")
            }
        }
    }
    
    
    /// A *value* read from an MMDB file. This parallels the `FieldType` tags, but includes an associated value
    /// and you can't mix rawValues and associated values
    indirect enum Value {
        case string(String)
        case map( [String:Value])
        case uint16( UInt16)
        case uint32( UInt32)
        case uint64( UInt64)
        case uint128( high: UInt64, low: UInt64)
        case int32( Int32)
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
            //
            // Read the ControlByte
            //
            let controlByte = bytes[pointer]
            pointer += 1
            
            let top3 = controlByte >> 5
            let payloadSize0 = controlByte & 0x1f
            let fieldType : FieldType
            let payloadSize : Int

            //
            // Decode the FieldType
            //
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
            
            //
            // Decode the payloadSize
            //
            switch payloadSize0 {
            case 29:
                payloadSize = 29 + Int(bytes[pointer])
                pointer += 1
            case 30:
                payloadSize = 285 + 256 * Int(bytes[pointer]) + Int(bytes[pointer+1])
                pointer += 2
            case 31:
                payloadSize = 65821 + 65536 * Int(bytes[pointer]) + 256 * Int(bytes[pointer+1]) + Int(bytes[pointer+2])
                pointer += 3
            default:
                payloadSize = Int(payloadSize0)
            }

            //
            // Read the Value. map and array are special, we need to handle them so we can
            // recurse. The rest of the field types are just scanned by their enum.
            //
            switch fieldType {
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
            case .array:
                var result : [Value] = []
                for _ in 0 ..< payloadSize {
                    guard let val = readValue(pointer: &pointer) else {
                        return nil
                    }
                    result.append(val)
                }
                return .array(result)
            default:
                let r = fieldType.scan(bytes: bytes.advanced(by: pointer), size: payloadSize)
                pointer += payloadSize
                return r
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
        
        guard case let .uint16(major) = metadata["binary_format_major_version"],
              case let .uint16(minor) = metadata["binary_format_minor_version"] else {
            print("no major and minor version")
            return nil
        }
        
        if major < 2 {
            print("not major version 2")
            return nil
        }
        
        majorVersion = UInt(major)
        minorVersion = UInt(minor)
        
        guard case let .uint64(epoch) = metadata["build_epoch"],
              case let .uint16(ipVersion) = metadata["ip_version"],
              case let .uint16(recordSize) = metadata["record_size"],
              case let .uint32(nodeCount) = metadata["node_count"],
              case let .string(databaseType) = metadata["database_type"] else {
            print("Missing some metadata")
            return nil
        }
        
        self.epoch = UInt(epoch)
        self.ipVersion = UInt(ipVersion)
        self.recordSize = UInt(recordSize)
        self.nodeCount = UInt(nodeCount)
        self.databaseType = databaseType
        
        searchTreeSize = ( ( self.recordSize * 2 ) / 8 ) * self.nodeCount
    }
    
    public convenience init?( from: URL) {
        guard let d = try? Data( contentsOf: from) else {
            return nil
        }
        self.init( data: d)
    }
    
}
