import Foundation

/// Used for decoding data from a file stream.
public struct Decoder {
    /// The file stream consisting of the MMDB database file.
    var fileStream: FileStream
    
    /// The data field type tag read from the MMDB file as given in *MaxMind DB File Format Specification 2.0*
    enum FieldType: UInt8 {
        case extended = 0
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
        case container = 12
        case endMarker = 13
        case boolean = 14
        case float = 15
    }
    
    /// A *value* read from an MMDB file. This parallels the `FieldType` tags, but includes an associated value
    /// and you can't mix rawValues and associated values
    public indirect enum Value {
        case string(String)
        case map([String:Value])
        case uint16(UInt16)
        case uint32(UInt32)
        case uint64(UInt64)
        case uint128(high: UInt64, low: UInt64)
        case int32(Int32)
        case double(Double)
        case float(Float)
        case bytes([UInt8])
        case array([Value])
        case boolean(Bool)
        
        /// Dump out a value using print().
        ///
        /// Just a little gift to developers, mostly so you can call it from the debugger.
        /// - Parameter level: The indentation level, roughly speaking, two spaces per indent level.
        func dump(level: Int = 0) {
            let indent = String(repeating: "  ", count: level)
            switch self {
            case .string(let s):
                print( "\(indent)\"\(s)\"")
            case .map(let m):
                print( "\(indent){")
                for (k,v) in m {
                    print( "\(indent): \(k) = ")
                    v.dump(level: level+1)
                }
                print( "\(indent)}")
            case .uint16(let v):
                print( "\(indent)\(v) u16")
            case .uint32(let v):
                print( "\(indent)\(v) u32")
            case .uint64(let v):
                print( "\(indent)\(v) u64")
            case .uint128(high: let high, low: let low):
                print( "\(indent)0x\(String(format:"%08x%08x", high, low)) u128")
            case .int32(let v):
                print( "\(indent)\(v) i32")
            case .double(let v):
                print( "\(indent)\(v) double")
            case .float(let v):
                print( "\(indent)\(v) float")
            case .bytes(let b):
                print( "\(indent)[\(b.count) bytes]")
            case .array(let elements):
                print( "\(indent){")
                elements.forEach{ $0.dump( level: level+1)}
                print( "\(indent)}")
            case .boolean(let v):
                print( "\(indent)\(v ? "true" : "false")")
            }
        }
    }
    
    init(fileStream: FileStream) {
        self.fileStream = fileStream
    }
    
    func decode(_ offset: inout Int, startingAt pointerBase: Int) throws -> Value {
        guard fileStream.indices.contains(offset) else {
            throw MMDBError.indexOutOfRange
        }
        let controlByte = fileStream[offset]
        offset += 1
        let fieldTypeValue = controlByte >> 5
        guard var type = FieldType(rawValue: fieldTypeValue) else {
            throw MMDBError.unknownFieldType(fieldTypeValue)
        }
        
        if type == .pointer {
            var pointer = try decodePointer(from: controlByte, with: pointerBase, at: &offset)
            return try decode(&pointer, startingAt: pointerBase)
        }
        
        if type == .extended {
            let extendedFieldTypeValue = fileStream[offset] + 7
            
            guard extendedFieldTypeValue >= 8 else {
                throw MMDBError.invalidFieldType(extendedFieldTypeValue)
            }
            
            guard let newType = FieldType(rawValue: extendedFieldTypeValue) else {
                throw MMDBError.unknownFieldType(extendedFieldTypeValue)
            }
            type = newType
            offset += 1
        }
        let size = try sizeFromControlByte(controlByte: controlByte, offset: &offset)
        return try decode(type, from: &offset, startingAt: pointerBase, with: size)
    }
    
    func sizeFromControlByte(controlByte: UInt8, offset: inout Int) throws -> Int {
        var size: Int = Int(controlByte) & 0x1f
        let bytesToRead = size < 29 ? 0 : size - 28
        let bytes = try fileStream.read(from: offset, numberOfBytes: Int(bytesToRead))
        let decoded = Int(Self.decodeUInt32(from: bytes))
        
        if size == 29 {
            size = 29 + decoded
        } else if size == 30 {
            size = 285 + decoded
        } else if size == 31 {
            size = (decoded & (0x0FFFFFFF >> (32 - (8 * bytesToRead)))) + 65821
        }
        offset += bytesToRead
        return size
    }
    
    func decode(_ type: FieldType, from offset: inout Int, startingAt pointerBase: Int, with size: Int) throws -> Value {
        let bytes = try fileStream.read(from: offset, numberOfBytes: size)
        
        switch type {
        case .map:
            return .map(try decodeMap(of: size, from: &offset, startingAt: pointerBase))
        case .array:
            return .array(try decodeArray(of: size, from: &offset, startingAt: pointerBase))
        case .boolean:
            break
        default:
            offset += size
        }
        
        switch type {
        case .boolean:
            return .boolean(Self.decodeBoolean(of: size))
        case .string:
            return .string(try Self.decodeString(from: bytes))
        case .double:
            return .double(try Self.decodeDouble(from: bytes))
        case .bytes:
            return .bytes(Array(bytes))
        case .uint16:
            return .uint16(Self.decodeUInt16(from: bytes))
        case .uint32:
            return .uint32(Self.decodeUInt32(from: bytes))
        case .int32:
            return .int32(Self.decodeInt32(from: bytes))
        case .uint64:
            return .uint64(Self.decodeUInt64(from: bytes))
        case .uint128:
            let uint128 = Self.decodeUInt128(from: bytes)
            return .uint128(high: uint128.high, low: uint128.low)
        case .float:
            return .float(try Self.decodeFloat(from: bytes))
        default:
            throw MMDBError.unknownFieldType(type.rawValue)
        }
    }
    
    func decodePointer(from controlByte: UInt8, with pointerBase: Int, at offset: inout Int) throws -> Int {
        let pointerSize = Int((controlByte >> 3) & 0x3)
        let buffer = try fileStream.read(from: offset, numberOfBytes: pointerSize + 1)
        offset += pointerSize + 1
        let pointerOffsets = [0, 2048, 526336, 0]
        
        let packed: ArraySlice<UInt8>
        if pointerSize == 3 {
            packed = buffer
        } else {
            let pointerSizeBits = controlByte & 0x7
            packed = [pointerSizeBits] + buffer
        }
        
        let value = Int(Self.decodeUInt32(from: packed)) + pointerBase + pointerOffsets[pointerSize]
        return value
    }
    
    static func decodeString(from bytes: ArraySlice<UInt8>) throws -> String {
        guard let string = String(bytes: bytes, encoding: .utf8) else {
            throw MMDBError.decodingError("Could not decode string from bytes: \(bytes)")
        }
        return string
    }
    
    static func decodeDouble(from bytes: ArraySlice<UInt8>) throws -> Double {
        guard bytes.count == 8 else {
            throw MMDBError.decodingError("Could not deocde double from bytes: \(bytes)")
        }
        return Double(bitPattern: decodeUInt64(from: bytes))
    }
    
    static func decodeUInt16(from bytes: ArraySlice<UInt8>) -> UInt16 {
        bytes.reduce(0) { ($0 << 8) | UInt16($1) }
    }
    
    static func decodeUInt32(from bytes: ArraySlice<UInt8>) -> UInt32 {
        bytes.reduce(0) { ($0 << 8) | UInt32($1) }
    }
    
    func decodeMap(of size: Int, from offset: inout Int, startingAt pointerBase: Int) throws -> [String: Value] {
        var map = [String: Value]()
        for _ in 0..<size {
            guard case let .string(key) = try decode(&offset, startingAt: pointerBase) else {
                throw MMDBError.decodingError("Map key is no String at offset: \(offset)")
            }
            let value = try decode(&offset, startingAt: pointerBase)
            map[key] = value
        }
        return map
    }
    
    static func decodeInt32(from bytes: ArraySlice<UInt8>) -> Int32 {
        Int32(bitPattern: decodeUInt32(from: bytes))
    }
    
    static func decodeUInt64(from bytes: ArraySlice<UInt8>) -> UInt64 {
        bytes.reduce(0) { ($0 << 8) | UInt64($1) }
    }
    
    static func decodeUInt128(from bytes: ArraySlice<UInt8>) -> (high: UInt64, low: UInt64) {
        var b = Array(bytes)
        if bytes.count < 16 {
            b = Array(repeating: 0, count: 16 - bytes.count) + b
        }
        let high = b[0..<8].reduce(0, { ($0 << 8) | UInt64($1) })
        let low = b[8..<16].reduce(0, { ($0 << 8) | UInt64($1) })
        return (high, low)
    }
    
    func decodeArray(of size: Int, from offset: inout Int, startingAt pointerBase: Int) throws -> [Value] {
        var array = [Value]()
        for _ in 0..<size {
            let value = try decode(&offset, startingAt: pointerBase)
            array.append(value)
        }
        return array
    }
    
    static func decodeBoolean(of size: Int) -> Bool {
        size != 0
    }
    
    static func decodeFloat(from bytes: ArraySlice<UInt8>) throws -> Float {
        guard bytes.count == 4 else {
            throw MMDBError.decodingError("Could not deocde float from bytes: \(bytes)")
        }
        return Float(bitPattern: decodeUInt32(from: bytes))
    }
}
