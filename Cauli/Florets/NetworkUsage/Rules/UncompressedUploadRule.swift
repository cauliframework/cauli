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

/// Finds request bodies sent without compression.
public struct UncompressedUploadRule: NetworkUsageRule {

    /// "uncompressed-upload"
    public let identifier = "uncompressed-upload"

    /// Request bodies smaller than this aren't worth compressing.
    public var minimumBodyBytes: Int64

    /// Creates the rule.
    public init(minimumBodyBytes: Int64 = 1_024) {
        self.minimumBodyBytes = minimumBodyBytes
    }

    /// Returns a hint if request bodies were sent without compression.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let affected = usage.transfers.filter { transfer in
            !transfer.isRequestCompressed && transfer.metrics.requestBodyBytes >= minimumBodyBytes
        }
        guard !affected.isEmpty else { return nil }
        let bytes = affected.reduce(Int64(0)) { $0 + $1.metrics.requestBodyBytes }
        let keys = Set(affected.map(\.endpointKey))
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .info,
            title: "Uncompressed uploads",
            summary: "\(NetworkUsageRuleSupport.count(keys.count, "endpoint", "endpoints")), \(NetworkUsageRuleSupport.format(bytes: bytes)) sent without compression",
            affectedEndpoints: usage.endpoints(withKeys: keys),
            estimatedSavingBytes: NetworkUsageRuleSupport.saving(compressing: bytes, ratio: NetworkUsageRuleSupport.defaultCompressionRatio),
            howToFix: "Compress large request bodies, e.g. with gzip, and send them with \"Content-Encoding: gzip\". The server has to accept compressed bodies."
        )
    }
}
