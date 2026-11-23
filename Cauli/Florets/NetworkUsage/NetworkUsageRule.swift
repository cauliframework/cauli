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

/// A rule finds one kind of avoidable network usage in a `NetworkUsageSnapshot`,
/// e.g. uncompressed responses. Every hint it returns is shown by the `NetworkUsageFloret`.
///
/// Rules are pure functions of the snapshot, so they are easy to test:
///
/// ```swift
/// struct ImageFormatRule: NetworkUsageRule {
///     let identifier = "legacy-image-format"
///     func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
///         let keys = Set(usage.transfers.filter { $0.responseContentType == "image/png" }.map(\.endpointKey))
///         guard !keys.isEmpty else { return nil }
///         return NetworkUsageHint(ruleIdentifier: identifier, severity: .info, title: "PNG images",
///                                 summary: "\(keys.count) endpoints serve PNG images",
///                                 affectedEndpoints: usage.endpoints(withKeys: keys),
///                                 estimatedSavingBytes: nil, howToFix: "Serve WebP or AVIF instead.")
///     }
/// }
///
/// let floret = NetworkUsageFloret(rules: NetworkUsageFloret.defaultRules + [ImageFormatRule()])
/// ```
public protocol NetworkUsageRule {

    /// Identifies the rule and its hints, e.g. "uncompressed-response".
    var identifier: String { get }

    /// Returns a hint if the usage shows what the rule looks for, else `nil`.
    func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint?
}
