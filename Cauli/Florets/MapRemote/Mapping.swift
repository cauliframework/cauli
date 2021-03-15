//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// A `Mapping` is a declaration of a single mapping. All urls that
/// match the description of the `sourceLocation` will be changed
/// according to the description in the `destinationLocation`.
/// All `nil` values are ignored in this case.
///
/// ## Examples
///
/// This `Mapping` will update all http requests to https requests.
/// ```swift
/// Mapping(name: "https-ify", sourceLocation: MappingLocation(scheme: "http"), destinationLocation: MappingLocation(scheme: "https"))
/// ```
///
/// This mapping will redirect all requests to localhost.
/// ```swift
/// Mapping(name: "map local", sourceLocation: MappingLocation(), destinationLocation: MappingLocation(host: "localhost")
/// ``` 
public struct Mapping {
    let name: String
    let sourceLocation: MappingLocation
    let destinationLocation: MappingLocation

    /// Initializes a new `Mapping`.
    /// - Parameters:
    ///   - name: The name of the `Mapping`. This is used to uniquely identify this mapping.
    ///   - sourceLocation: This defines all urls this `Mapping` should apply to.
    ///   - destinationLocation: This defines the changes for the url.
    public init(name: String, sourceLocation: MappingLocation, destinationLocation: MappingLocation) {
        self.name = name
        self.sourceLocation = sourceLocation
        self.destinationLocation = destinationLocation
    }
}

/// A mapping location describes a given part of a url.
/// The mapping location can be used to either filter urls, or to apply changes on the url.
public struct MappingLocation {
    let `protocol`: Protocol?
    let host: String?
    let port: Int?
    let path: String?
    let query: String?

    /// Instantiates a new `MappingLocation`.
    /// - Parameters:
    ///   - protocol: The protocol, http or https, of the url.
    ///   - host: The host of the url.
    ///   - port: The port of the url.
    ///   - path: The path of the url. Should begin with a `/`.
    ///   - query: The query of the url. Should contain the `?`.
    public init(`protocol`: Protocol? = nil, host: String? = nil, port: Int? = nil, path: String? = nil, query: String? = nil) {
        self.`protocol` = `protocol`
        self.host = host
        self.port = port
        self.path = path
        self.query = query
    }
}

internal extension MappingLocation {
    func matches(url: URL) -> Bool {
        if let `protocol` = `protocol`, url.scheme != `protocol`.rawValue {
            return false
        }
        if let host = host, url.host != host {
            return false
        }
        if let port = port, url.port != port {
            return false
        }
        if let path = path, url.path != path {
            return false
        }
        if let query = query, url.query != query {
            return false
        }
        return true
    }

    func updating(url oldUrl: URL) -> URL {
        guard var components = URLComponents(url: oldUrl, resolvingAgainstBaseURL: false) else { return oldUrl }
        if let `protocol` = `protocol` {
            components.scheme = `protocol`.rawValue
        }
        if let host = host {
            components.host = host
        }
        if let port = port {
            components.port = port
        }
        if let path = path {
            components.path = path
        }
        if let query = query {
            components.query = query
        }
        return components.url ?? oldUrl
    }
}

public extension MappingLocation {
    enum `Protocol`: String {
        case http
        case https
    }
}
