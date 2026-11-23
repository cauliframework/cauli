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

/// How a request was transferred: the bytes sent and received over the network, and how it was loaded.
/// Taken from the `URLSessionTaskMetrics` of the request Cauli performs.
public struct TransferMetrics: Codable, Equatable {

    /// The bytes of the request's header fields sent over the network.
    public var requestHeaderBytes: Int64

    /// The bytes of the request's body sent over the network.
    public var requestBodyBytes: Int64

    /// The bytes of the response's header fields received over the network.
    public var responseHeaderBytes: Int64

    /// The bytes of the response's body received over the network, before it was decompressed.
    public var responseBodyBytes: Int64

    /// The bytes of the response's body after it was decompressed, e.g. from gzip.
    /// The same as `responseBodyBytes` for an uncompressed response.
    public var responseBodyBytesDecoded: Int64

    /// `true` if the response was loaded from the local cache, without a request over the network.
    public var isFromCache: Bool

    /// The protocol of the response, e.g. "h2", "h3" or "http/1.1". `nil` if unknown.
    public var networkProtocol: String?

    /// `true` if the request was sent over a connection that was already open.
    public var isReusedConnection: Bool

    /// The time from the start of the request until the response was complete, in seconds.
    public var duration: TimeInterval

    /// All bytes sent over the network.
    public var sentBytes: Int64 {
        requestHeaderBytes + requestBodyBytes
    }

    /// All bytes received over the network.
    public var receivedBytes: Int64 {
        responseHeaderBytes + responseBodyBytes
    }

    /// Creates metrics with the given values, e.g. for tests of florets that use them.
    public init(requestHeaderBytes: Int64, requestBodyBytes: Int64, responseHeaderBytes: Int64, responseBodyBytes: Int64, responseBodyBytesDecoded: Int64, isFromCache: Bool, networkProtocol: String?, isReusedConnection: Bool, duration: TimeInterval) {
        self.requestHeaderBytes = requestHeaderBytes
        self.requestBodyBytes = requestBodyBytes
        self.responseHeaderBytes = responseHeaderBytes
        self.responseBodyBytes = responseBodyBytes
        self.responseBodyBytesDecoded = responseBodyBytesDecoded
        self.isFromCache = isFromCache
        self.networkProtocol = networkProtocol
        self.isReusedConnection = isReusedConnection
        self.duration = duration
    }
}

extension TransferMetrics {
    /// Sums up the bytes of all transactions, e.g. of a redirect and its target.
    /// How the request was loaded is taken from the last transaction, which delivered the response.
    init(_ metrics: URLSessionTaskMetrics) {
        let transactions = metrics.transactionMetrics
        let last = transactions.last
        self.init(
            requestHeaderBytes: transactions.reduce(0) { $0 + $1.countOfRequestHeaderBytesSent },
            requestBodyBytes: transactions.reduce(0) { $0 + $1.countOfRequestBodyBytesSent },
            responseHeaderBytes: transactions.reduce(0) { $0 + $1.countOfResponseHeaderBytesReceived },
            responseBodyBytes: transactions.reduce(0) { $0 + $1.countOfResponseBodyBytesReceived },
            responseBodyBytesDecoded: transactions.reduce(0) { $0 + $1.countOfResponseBodyBytesAfterDecoding },
            isFromCache: last?.resourceFetchType == .localCache,
            networkProtocol: last?.networkProtocolName,
            isReusedConnection: last?.isReusedConnection ?? false,
            duration: metrics.taskInterval.duration
        )
    }
}
