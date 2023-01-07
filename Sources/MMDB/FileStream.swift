import Foundation

class FileStream {
    private var bytes: [UInt8]
    
    init(data: Data) {
        bytes = data.withUnsafeBytes{ body in
            let buffer = body.bindMemory(to: UInt8.self)
            return .init(buffer)
        }
    }
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    subscript(index: Int) -> UInt8 {
        bytes[index]
    }
    
    func read(from offset: Int, numberOfBytes: Int) throws -> ArraySlice<UInt8> {
        guard offset + numberOfBytes <= bytes.count else {
            throw MMDBError.indexOutOfRange
        }
        return bytes[offset..<offset + numberOfBytes]
    }
    
    var count: Int { bytes.count }
    
    var indices: Range<Array<UInt8>.Index> { bytes.indices }
    
    func findMetadataStart() throws -> Int {
        // This is "\xab\xcd\xefMaxMind.com" per the spec, but that is invalid UTF8, so we are kind of screwed there.
        let marker : [UInt8] = [0xab, 0xcd, 0xef, 0x4D, 0x61, 0x78, 0x4D, 0x69, 0x6E, 0x64, 0x2E, 0x63, 0x6F, 0x6D]
        
        // Look back from the end of the file until we find the last match.
        for i in (0 ..< bytes.count - marker.count).reversed()  {
            guard bytes[i] == marker.first! else { continue }
            if marker.indices.allSatisfy({ bytes[i + $0] == marker[$0]}) {
                return i + marker.count
            }
        }
        
        throw MMDBError.metadataError("Could not find metadata")
    }
}
