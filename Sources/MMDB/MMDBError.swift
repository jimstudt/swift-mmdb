enum MMDBError: Error {
    case indexOutOfRange
    case unsupportedRecordSize
    case invalidDatabaseType(_ databaseType: String)
    case invalidFieldType(_ FieldType: UInt8)
    case unknownFieldType(_ fieldType: UInt8)
    case notFound(_ at: String)
    case metadataError(_ description: String)
    case corruptDatabase(_ description: String)
    case decodingError(_ description: String)
}
