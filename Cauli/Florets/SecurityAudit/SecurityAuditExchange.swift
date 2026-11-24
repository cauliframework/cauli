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

/// A request and its response, as a `SecurityAuditRule` checks them. Bodies are not included.
public struct SecurityAuditExchange {

    /// The request as it was sent.
    public let request: URLRequest

    /// The response, `nil` if the request failed.
    public let response: HTTPURLResponse?

    /// The TLS version of the connection, e.g. "TLS 1.3", if known.
    public let tlsVersion: String?

    /// Creates an exchange, e.g. in the tests of a rule.
    public init(request: URLRequest, response: HTTPURLResponse? = nil, tlsVersion: String? = nil) {
        self.request = request
        self.response = response
        self.tlsVersion = tlsVersion
    }

    /// The URL of the request.
    public var url: URL? {
        request.url
    }

    /// The lowercased host of the request, e.g. "api.example.com".
    public var host: String? {
        request.url?.host?.lowercased()
    }

    /// Whether the request is sent over plain HTTP.
    public var isCleartext: Bool {
        request.url?.scheme?.lowercased() == "http"
    }

    /// Whether the request is sent over HTTPS.
    public var isHTTPS: Bool {
        request.url?.scheme?.lowercased() == "https"
    }

    /// Whether the request stays on the device, e.g. to `localhost` or `127.0.0.1`.
    public var isLoopback: Bool {
        guard let host = host else { return false }
        return host == "localhost" || host.hasSuffix(".localhost") || host.hasPrefix("127.") || host == "::1" || host == "[::1]"
    }

    /// The value of a request header field, its name compared case-insensitively.
    public func requestHeader(_ name: String) -> String? {
        request.allHTTPHeaderFields?.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// The value of a response header field, its name compared case-insensitively.
    public func responseHeader(_ name: String) -> String? {
        response?.value(forHTTPHeaderField: name)
    }
}
