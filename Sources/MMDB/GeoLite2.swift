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
public class GeoLite2CountryDatabase {
    private let db : MMDB
    private let zero96 : UInt
    
    public var majorVersion : UInt { db.majorVersion }
    public var minorVersion : UInt { db.minorVersion }
    public var epoch : UInt { db.epoch }
    public var ipVersion : UInt { db.ipVersion }
    public var databaseType : String { db.databaseType }

    public init?( data: Data) {
        guard let d = MMDB(data: data) else {
            return nil
        }
        
        // check that we really the right database type
        if d.databaseType != "GeoLite2-Country" { return nil }
        
        guard case let .partial(zero64) = d.search(value: 0, bits: 64),
              case let .partial(zero96) = d.search(starting: zero64, value: 0, bits: 32) else {
            return nil
        }

        self.db = d
        self.zero96 = zero96
    }

    public convenience init?( from: URL) {
        guard let d = try? Data( contentsOf: from) else {
            return nil
        }
        self.init( data: d)
    }
    
    /// Get the MMDB.Value record for an IP address in text form. Does not look up host names.
    /// You will need to use a numeric form. It accepts both IPv4 and IPv6 addresses.
    /// - Parameter address: A numeric IPv4 or IPv6 address as accepted by `inet_addr`
    /// or `inet_pton`
    /// - Returns: The MMDB.Value record found, or a .notFound, or maybe a .failure if your name
    /// was not valid.
    public func search( address: String) -> MMDB.SearchResult {
        let ipv4 = inet_addr(address)
        if ipv4 != UInt32.max {
            return db.search(starting: zero96, value: UInt( ipv4.bigEndian)<<32, bits: 32)
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
            let parts = [ a.bigEndian, b.bigEndian, c.bigEndian, d.bigEndian]
            var n : UInt = 0
            for p in parts {
                print( String(format:"%08x", p))
                switch db.search(starting: n, value: UInt(p)<<32, bits: 32) {
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
    
    /// Do the search from ascii numeric internet address but just fetch out the ISO country code.
    /// - Parameter address: A numeric IPv4 or IPv6 address as accepted by `inet_addr`
    /// or `inet_pton`
    /// - Returns: A two letter ISO country code, capitalized, or nil if not found (or error)
    public func countryCode( address: String) -> String? {
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
