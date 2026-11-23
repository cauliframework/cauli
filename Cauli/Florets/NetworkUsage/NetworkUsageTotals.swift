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

/// Counts of the transfers of the whole session, a host or an endpoint.
public struct NetworkUsageTotals: Codable, Equatable {

    /// All requests, including the ones loaded from the cache.
    public var requests = 0

    /// The requests loaded from the local cache, without a request over the network.
    public var requestsFromCache = 0

    /// The requests that opened a new connection.
    public var newConnections = 0

    /// All bytes sent over the network, header fields and bodies.
    public var sentBytes: Int64 = 0

    /// All bytes received over the network, header fields and bodies.
    public var receivedBytes: Int64 = 0

    /// The bytes of the response bodies received over the network.
    public var receivedBodyBytes: Int64 = 0

    /// The bytes of the response bodies after they were decompressed.
    public var decodedBodyBytes: Int64 = 0

    /// Creates empty totals.
    public init() {}

    /// The requests performed over the network.
    public var networkRequests: Int {
        requests - requestsFromCache
    }

    /// The bytes compression saved: decoded minus received body bytes.
    public var savedByCompression: Int64 {
        max(0, decodedBodyBytes - receivedBodyBytes)
    }

    /// The share of network requests sent over an already open connection, from 0 to 1.
    /// `nil` without network requests.
    public var connectionReuse: Double? {
        guard networkRequests > 0 else { return nil }
        return Double(networkRequests - newConnections) / Double(networkRequests)
    }

    /// Adds a transfer to the totals.
    public mutating func add(_ transfer: NetworkUsageTransfer) {
        let metrics = transfer.metrics
        requests += 1
        if metrics.isFromCache {
            requestsFromCache += 1
            return
        }
        if !metrics.isReusedConnection {
            newConnections += 1
        }
        sentBytes += metrics.sentBytes
        receivedBytes += metrics.receivedBytes
        receivedBodyBytes += metrics.responseBodyBytes
        decodedBodyBytes += metrics.responseBodyBytesDecoded
    }
}
