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

/// Finds large responses.
public struct LargePayloadRule: NetworkUsageRule {

    /// "large-payload"
    public let identifier = "large-payload"

    /// Responses with a body of at least this many bytes are large.
    public var minimumBodyBytes: Int64

    /// Creates the rule.
    public init(minimumBodyBytes: Int64 = 500_000) {
        self.minimumBodyBytes = minimumBodyBytes
    }

    /// Returns a hint if large responses were received.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let large = usage.transfers.filter { !$0.metrics.isFromCache && $0.metrics.responseBodyBytes >= minimumBodyBytes }
        guard let largest = large.map(\.metrics.responseBodyBytes).max() else { return nil }
        let keys = Set(large.map(\.endpointKey))
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .info,
            title: "Large payloads",
            summary: "\(NetworkUsageRuleSupport.count(large.count, "response", "responses")) over \(NetworkUsageRuleSupport.format(bytes: minimumBodyBytes)), the largest \(NetworkUsageRuleSupport.format(bytes: largest))",
            affectedEndpoints: usage.endpoints(withKeys: keys),
            estimatedSavingBytes: nil,
            howToFix: "Check whether the app needs all of it: paginate lists, request images in the size they are shown, or use more efficient formats."
        )
    }
}
