//
//  GeoLite2.swift
//  
//
//  Created by Jim Studt on 4/18/22.
//

import Foundation

/// Provide access to a GeoLite2-Country.mmdb database file. The file is read on instantiation
/// and kept in memory for as long as the instance persists.
///
/// It is expected that a server will create one of these at startup, and then perhaps replace it
/// with a new one from time to time to get updates.  The underlying data files from MaxMind
/// only update once a week for the free developer files.
///
/// Note: You can use the MMDB .search methods to get the entire value record for an
/// address. The `countryCode` method is just an encapsulation of a common use case.
/// 
public class GeoLite2CountryDatabase : MMDB {
    override public init(data: Data) throws {
        try super.init(data: data)
        
        // check that we really the right database type
        if metadata.databaseType != "GeoLite2-Country" { throw MMDBError.invalidDatabaseType(metadata.databaseType) }
    }

    /// Do the search from ascii numeric internet address but just fetch out the ISO country code.
    /// - Parameter address: A numeric IPv4 or IPv6 address as accepted by `inet_addr`
    /// or `inet_pton`
    /// - Returns: A two letter ISO country code, capitalized, or nil if not found (or error)
    public func countryCode(address: String) throws -> String? {
        switch search(address: address) {
        case .notFound:
            return nil
        case .partial(_):
            return nil  // shouldn't happen
        case .value(let v):
            guard case let .map(m) = v,
                  case let .map(country) = m["country"],
                  case let .string(code) = country["iso_code"] else {
                return nil
            }
            return code
        case .failed(_):
            return nil
        }
    }
}
