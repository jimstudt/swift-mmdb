struct Metadata {
    let nodeCount: UInt
    let recordSize: UInt
    let ipVersion: UInt
    let databaseType: String
    let languages: [Decoder.Value]
    let majorVersion: UInt
    let minorVersion: UInt
    let epoch: UInt
    let description: [String: Decoder.Value]

    let searchTreeSize: UInt
    let dataSectionStart: UInt
    let nodeByteSize: Int
    
    init(_ metadata: [String: Decoder.Value]) throws {
        guard case let .uint16(major) = metadata["binary_format_major_version"],
              case let .uint16(minor) = metadata["binary_format_minor_version"] else {
            throw MMDBError.metadataError("Could not find database version")
        }
        
        if major < 2 {
            throw MMDBError.metadataError("Database is not of major version 2")
        }
        
        self.majorVersion = UInt(major)
        self.minorVersion = UInt(minor)
        
        guard case let .uint64(epoch) = metadata["build_epoch"] else {
            throw MMDBError.metadataError("Could not decode build epoch")
        }
        guard case let .uint16(ipVersion) = metadata["ip_version"] else {
            throw MMDBError.metadataError("Could not decode ip version")
        }
        guard case let .uint16(recordSize) = metadata["record_size"] else {
            throw MMDBError.metadataError("Could not decode record size")
        }
        guard case let .uint32(nodeCount) = metadata["node_count"] else {
            throw MMDBError.metadataError("Could not decode node count")
        }
        guard case let .string(databaseType) = metadata["database_type"] else {
            throw MMDBError.metadataError("Could not decode database type")
        }
        
        self.epoch = UInt(epoch)
        self.ipVersion = UInt(ipVersion)
        self.recordSize = UInt(recordSize)
        self.nodeByteSize = Int(recordSize / 4)
        self.nodeCount = UInt(nodeCount)
        self.databaseType = databaseType
        
        guard case let .array(languages) = metadata["languages"],
              case let .map(description) = metadata["description"]
        else {
            throw MMDBError.metadataError("Could not decode languages or description")
        }
        self.languages = languages
        self.description = description
        
        self.searchTreeSize = ((self.recordSize * 2) / 8) * self.nodeCount
        
        self.dataSectionStart = searchTreeSize + 16
    }
}
