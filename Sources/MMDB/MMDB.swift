import Foundation

public class MMDB {
    private let fileStream: FileStream
    let metadata: Metadata
    private let decoder: Decoder
    private(set) lazy var ipv4Root: UInt = computeIPv4Root()
    
    /// Initializes a database from an url.
    /// - Parameter url: The url at which the database file is located.
    public convenience init(from url: URL) throws {
        guard let data = try? Data(contentsOf: url) else {
            throw MMDBError.notFound(url.absoluteString)
        }
        try self.init(data: data)
    }
    
    /// Initializes a database from data.
    /// - Parameter data: The data representing the MMDB.
    public init(data: Data) throws {
        self.fileStream = FileStream(data: data)
        
        var metadataStart = try fileStream.findMetadataStart()
        self.decoder = Decoder(fileStream: self.fileStream)
        guard case let .map(metadataMap) = try decoder.decode(&metadataStart, startingAt: metadataStart) else {
            throw MMDBError.metadataError("Could not decode metadata")
        }
        self.metadata = try Metadata(metadataMap)
        if metadata.searchTreeSize > metadataStart {
            throw MMDBError.corruptDatabase("Invalid node count")
        }
    }
    
    public enum SearchResult {
        case notFound
        case partial(UInt)
        case value(Decoder.Value)
        case failed(String)
    }
    
    func computeIPv4Root() -> UInt {
        if metadata.ipVersion == 6,
           case let .partial(zero64) = search(value: 0, bits: 64),
           case let .partial(zero96) = search(starting: zero64, value: 0, bits: 32) {
            return zero96
        }
        return 0
    }
    
    // MARK: - Search
    
    /// Get the MMDB.Value record for an IP address in text form. Does not look up host names.
    /// You will need to use a numeric form. It accepts both IPv4 and IPv6 addresses.
    /// - Parameter address: A numeric IPv4 or IPv6 address as accepted by `inet_addr`
    /// or `inet_pton`
    /// - Returns: The MMDB.Value record found, or a .notFound, or maybe a .failure if your name
    /// was not valid.
    public func search(address: String) -> SearchResult {
        let ipv4 = inet_addr(address)
        if ipv4 != UInt32.max {
            return search(starting: ipv4Root, value: UInt(ipv4.bigEndian)<<32, bits: 32)
        }
        
        var ipv6 = in6_addr()
        switch withUnsafeMutablePointer(to: &ipv6, ({ inet_pton(AF_INET6, address, UnsafeMutablePointer($0))})) {
        case -1:
            break  // error
        case 0:
            break  // not a valid address
        default:
#if canImport(Glibc)
            let (a,b,c,d) = ipv6.__in6_u.__u6_addr32
#else
            let (a,b,c,d) = ipv6.__u6_addr.__u6_addr32
#endif
            let parts = [a.bigEndian, b.bigEndian, c.bigEndian, d.bigEndian]
            var n : UInt = 0
            for p in parts {
                switch search(starting: n, value: UInt(p)<<32, bits: 32) {
                    
                case .notFound:
                    return .notFound
                case .partial(let nn):
                    n = nn
                case .value(let v):
                    return .value(v)
                case .failed(let m):
                    return .failed(m)
                }
            }
        }
        
        return .notFound
    }
    
    /// Search the database for a match.
    ///
    /// The bits to be search *must* be in the high order bit positions in `value`. It is presumed that there will
    /// be a layer above MMDB, say one that deals with IPv4 and IPv6 addresses and they will absorb the fiddling
    /// with bits.
    ///
    /// Using `starting` you can start from some place other than the root of the search tree. You will want to have
    /// received this value from a `.partial` result of a preceding search. (_Hint:_ if you are looking up IPv4
    /// addresses in an IPv6 database, you probably want to start *after* the first 96 zeroes have been fed into the
    /// search.
    /// - Parameters:
    ///   - starting: The starting node. This defaults to 0 for the root of the database. You might also pass in a value you
    ///   recieved as a .partial result from `search`.
    ///   - value: The binary value you are searching for. The bits must begin at the most significant bit.
    ///   - bits: The maximum number of bits to process. If an answer has not been determined, then
    ///   a .partial result will be given at this point.
    /// - Returns: A `SearchResult`, so a value, a 'not found' indicator, a partial result marker, or a failure message.
    /// Failures should never occur in proper use of an uncorrupted database. You might get them during development.
    func search(starting: UInt = 0, value: UInt, bits: Int) -> SearchResult {
        if starting >= metadata.nodeCount {
            return .failed("Invalid starting node number")
        }
        if bits < 0 || bits > 64 {
            return .failed("Invalid bit count")
        }
        var n = starting
        for b in 0 ..< bits {
            
            do {
                if (value & (1 << (63-b))) == 0 {
                    n = try node(n, side: 0)
                } else {
                    n = try node(n, side: 1)
                }
            } catch {
                return .failed(error.localizedDescription)
            }
            if n == metadata.nodeCount {
                return .notFound
            }
            if n > metadata.nodeCount {
                let dataOffset = n - metadata.nodeCount - 16
                var pointer : Int = Int(metadata.dataSectionStart + dataOffset)
                guard let value = try? decoder.decode(&pointer, startingAt: Int(metadata.dataSectionStart)) else {
                    return .failed("Failed to read value in search")
                }
                return .value(value)
            }
        }
        return .partial(n)
    }
    
    func search<T>(value: [T], bits: Int) -> SearchResult where T : FixedWidthInteger {
        var n : UInt = 0
        var togo = bits
        
        for v in value {
            let c = UInt(v) << (64 - T.bitWidth)
            switch search(starting: n, value: c, bits: min( togo, T.bitWidth)) {
            case .notFound:
                return .notFound
            case .partial(let nn):
                n = nn
                togo -= T.bitWidth
            case .value(let vv):
                return .value(vv)
            case .failed(let m):
                return .failed(m)
            }
        }
        return .partial(n)
    }
    
    public func enumerate(_ handler: ([UInt32], Int) throws -> Void) throws {
        func crunch(_ path: [UInt8]) -> [UInt32] {
            var result : [UInt32] = []
            var accumulate : UInt32 = 0
            
            for i in path.indices {
                accumulate = (accumulate << 1) + UInt32(path[i] & 1)
                if (i % 32) == 31 {
                    result.append(accumulate)
                    accumulate = 0
                }
            }
            if path.count % 32 != 0 {
                accumulate = accumulate << ( 32 - (path.count % 32) )
                result.append(accumulate)
            }
            return result
        }
        
        func doNode(_ n: UInt, path: [UInt8]) throws {
            // Catch and abort loops in the search tree
            if metadata.ipVersion == 4 && path.count >= 32 { return }
            if metadata.ipVersion == 6 && path.count >= 128 { return }
            
            let left = try node(n, side: 0)
            if left > metadata.nodeCount {
                try handler(crunch(path + [0]), path.count+1 )
            } else if left < metadata.nodeCount {
                try doNode( left, path: path + [0])
            }
            // = nodeCount means 'not found'
            
            let right = try node(n, side:1)
            if right > metadata.nodeCount {
                try handler(crunch(path + [1]), path.count+1)
            } else if right < metadata.nodeCount {
                try doNode(right, path: path + [1])
            }
            // = nodeCount means 'not found'
        }
        
        try doNode(0, path:[])
    }
    
    // MARK: - Nodes
    
    private func node(_ number: UInt, side: UInt) throws -> UInt {
        switch metadata.recordSize {
        case 24:
            return try node6(number, side: side)
        case 28:
            return try node7(number, side: side)
        case 32:
            return try node8(number, side: side)
        default:
            throw MMDBError.unsupportedRecordSize
        }
    }
    
    func node6(_ number: UInt, side: UInt) throws -> UInt {
        let bytesToRead = 3
        let base = side == 0 ? Int(number * 6) : Int(number * 6) + bytesToRead
        return UInt(Decoder.decodeUInt32(from: try fileStream.read(from: base, numberOfBytes: bytesToRead)))
    }
    
    func node7(_ number: UInt, side: UInt) throws -> UInt {
        let bytesToRead = 3
        var base = Int(number * 7)
        let middle = fileStream[base + bytesToRead]
        base += side == 0 ? 0 : bytesToRead + 1
        let relevantMiddleBits = side == 0 ? middle >> 4 : middle & 0x0f
        var bytes = try fileStream.read(from: base, numberOfBytes: bytesToRead)
        bytes.insert(relevantMiddleBits, at: bytes.indices.startIndex)
        return (UInt(Decoder.decodeUInt32(from: bytes)))
    }
    
    func node8(_ number: UInt, side: UInt) throws -> UInt {
        let bytesToRead = 4
        let base = side == 0 ? Int(number * 8) : Int(number * 8) + bytesToRead
        return UInt(Decoder.decodeUInt32(from: try fileStream.read(from: base, numberOfBytes: bytesToRead)))
    }
}
