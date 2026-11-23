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

/// Finds text, JSON, XML and JavaScript responses sent without compression.
public struct UncompressedResponseRule: NetworkUsageRule {

    /// "uncompressed-response"
    public let identifier = "uncompressed-response"

    /// Response bodies smaller than this aren't worth compressing.
    public var minimumBodyBytes: Int64

    /// Creates the rule.
    public init(minimumBodyBytes: Int64 = 1_024) {
        self.minimumBodyBytes = minimumBodyBytes
    }

    /// Returns a hint if compressible responses were received without compression.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let affected = usage.transfers.filter { transfer in
            !transfer.metrics.isFromCache
                && !transfer.isResponseCompressed
                && NetworkUsageRuleSupport.isCompressible(transfer.responseContentType)
                && transfer.metrics.responseBodyBytes >= minimumBodyBytes
        }
        guard !affected.isEmpty else { return nil }
        let bytes = affected.reduce(Int64(0)) { $0 + $1.metrics.responseBodyBytes }
        let keys = Set(affected.map(\.endpointKey))
        let ratio = NetworkUsageRuleSupport.compressionRatio(in: usage)
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Uncompressed responses",
            summary: "\(NetworkUsageRuleSupport.count(keys.count, "endpoint", "endpoints")), \(NetworkUsageRuleSupport.format(bytes: bytes)) without compression",
            affectedEndpoints: usage.endpoints(withKeys: keys),
            estimatedSavingBytes: NetworkUsageRuleSupport.saving(compressing: bytes, ratio: ratio),
            howToFix: "Enable gzip or brotli for these content types on the server. The app needs no change: URLSession already sends \"Accept-Encoding: gzip, deflate, br\" with every request."
        )
    }
}
