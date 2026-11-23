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

/// Finds the same GET request sent again shortly after the previous one.
public struct DuplicateRequestRule: NetworkUsageRule {

    /// "duplicate-request"
    public let identifier = "duplicate-request"

    /// A request counts as duplicate if the same url was requested less than this many seconds before.
    public var window: TimeInterval

    /// The number of requests to the same url within the window that make a hint.
    public var minimumCount: Int

    /// Creates the rule.
    public init(window: TimeInterval = 10, minimumCount: Int = 3) {
        self.window = window
        self.minimumCount = minimumCount
    }

    /// Returns a hint if urls were requested repeatedly within the window.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let requests = usage.transfers.filter { $0.method == "GET" && !$0.metrics.isFromCache }
        var duplicates: [NetworkUsageTransfer] = []
        for transfers in Dictionary(grouping: requests, by: \.url).values {
            let sorted = transfers.sorted { $0.date < $1.date }
            let repeated = zip(sorted, sorted.dropFirst())
                .filter { previous, next in next.date.timeIntervalSince(previous.date) < window }
                .map(\.1)
            if repeated.count + 1 >= minimumCount {
                duplicates += repeated
            }
        }
        guard !duplicates.isEmpty else { return nil }
        let keys = Set(duplicates.map(\.endpointKey))
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Duplicate requests",
            summary: "\(NetworkUsageRuleSupport.count(duplicates.count, "request", "requests")) repeated within \(Int(window)) s",
            affectedEndpoints: usage.endpoints(withKeys: keys),
            estimatedSavingBytes: duplicates.reduce(Int64(0)) { $0 + $1.metrics.receivedBytes },
            howToFix: "Reuse the response instead of requesting it again, e.g. keep it in memory for a short time, or share one request between the parts of the app that need it."
        )
    }
}
