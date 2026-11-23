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

/// Finds repeated GET requests whose responses can't be cached or revalidated.
public struct NotCacheableRule: NetworkUsageRule {

    /// "not-cacheable"
    public let identifier = "not-cacheable"

    /// The number of requests to the same url that make a hint.
    public var minimumRequests: Int

    /// Creates the rule.
    public init(minimumRequests: Int = 3) {
        self.minimumRequests = minimumRequests
    }

    /// Returns a hint if urls were requested repeatedly and their responses have no caching headers.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let requests = usage.transfers.filter { transfer in
            transfer.method == "GET"
                && !transfer.metrics.isFromCache
                && !transfer.isCacheable
                && (200..<300).contains(transfer.statusCode ?? 0)
        }
        let repeated = Dictionary(grouping: requests, by: \.url).values.filter { $0.count >= minimumRequests }
        guard !repeated.isEmpty else { return nil }
        let keys = Set(repeated.compactMap(\.first?.endpointKey))
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .info,
            title: "Not cacheable",
            summary: "\(NetworkUsageRuleSupport.count(keys.count, "endpoint", "endpoints")) without Cache-Control, ETag or Last-Modified",
            affectedEndpoints: usage.endpoints(withKeys: keys),
            estimatedSavingBytes: nil,
            howToFix: "Send \"Cache-Control\" with a max-age, or an \"ETag\" or \"Last-Modified\" header field, so URLSession can reuse or revalidate the response."
        )
    }
}
