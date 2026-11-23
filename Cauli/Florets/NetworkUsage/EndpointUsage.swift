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

/// The usage of one endpoint, e.g. "GET /users/:id" of "api.example.com".
public struct EndpointUsage: Codable, Equatable {

    /// The host of the endpoint.
    public let host: String

    /// The HTTP method of the endpoint.
    public let method: String

    /// The path pattern of the endpoint, e.g. "/users/:id".
    public let path: String

    /// The counts of all its transfers.
    public internal(set) var totals = NetworkUsageTotals()

    /// Creates the usage of an endpoint without transfers.
    public init(host: String, method: String, path: String) {
        self.host = host
        self.method = method
        self.path = path
    }

    /// E.g. "GET /users/:id".
    public var name: String {
        "\(method) \(path)"
    }

    /// The same as `NetworkUsageTransfer.endpointKey` of its transfers.
    public var key: String {
        "\(method) \(host)\(path)"
    }
}
