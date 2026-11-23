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

@testable import Cauliframework
import Foundation

/// Builds transfers and snapshots for the tests of the NetworkUsageFloret and its rules.
enum NetworkUsageFixture {

    static func transfer(
        method: String = "GET",
        url: String = "https://api.example.com/users/42",
        status: Int? = 200,
        contentType: String? = "application/json",
        contentEncoding: String? = nil,
        requestEncoding: String? = nil,
        cacheable: Bool = true,
        requestBody: Int64 = 0,
        body: Int64 = 2_000,
        decodedBody: Int64? = nil,
        fromCache: Bool = false,
        protocolName: String? = "h2",
        reused: Bool = true,
        date: Date = Date(timeIntervalSinceReferenceDate: 0),
        duration: TimeInterval = 0.1
    ) -> NetworkUsageTransfer {
        let parsedURL = URL(string: url)!
        let metrics = TransferMetrics(requestHeaderBytes: 300, requestBodyBytes: requestBody, responseHeaderBytes: 200, responseBodyBytes: body, responseBodyBytesDecoded: decodedBody ?? body, isFromCache: fromCache, networkProtocol: protocolName, isReusedConnection: reused, duration: duration)
        return NetworkUsageTransfer(date: date, method: method, url: url, host: parsedURL.host!, endpoint: EndpointPattern.pattern(for: parsedURL.path), statusCode: status, responseContentType: contentType, responseContentEncoding: contentEncoding, requestContentEncoding: requestEncoding, isCacheable: cacheable, metrics: metrics)
    }

    static func snapshot(_ transfers: [NetworkUsageTransfer]) -> NetworkUsageSnapshot {
        let store = NetworkUsageStore(maximumTransfers: 10_000)
        transfers.forEach(store.add)
        return store.snapshot()
    }
}
