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

/// A finding of a `NetworkUsageRule`: where the app could use less network, and how.
public struct NetworkUsageHint: Equatable {

    /// How important a hint is. Warnings are listed first.
    public enum Severity: Int, Comparable {
        /// Worth a look.
        case info
        /// Avoidable usage that is usually easy to fix.
        case warning

        /// Orders by importance, `info` before `warning`.
        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// The `identifier` of the rule that found it.
    public var ruleIdentifier: String

    /// How important the hint is.
    public var severity: Severity

    /// E.g. "Uncompressed responses".
    public var title: String

    /// One line about what was found, e.g. "3 JSON endpoints, 1.1 MB without compression".
    public var summary: String

    /// The endpoints the hint is about, the most received bytes first.
    public var affectedEndpoints: [EndpointUsage]

    /// How many bytes fixing it would likely save. `nil` if that can't be estimated.
    public var estimatedSavingBytes: Int64?

    /// What to change to fix it.
    public var howToFix: String

    /// Creates a hint.
    public init(ruleIdentifier: String, severity: Severity, title: String, summary: String, affectedEndpoints: [EndpointUsage], estimatedSavingBytes: Int64?, howToFix: String) {
        self.ruleIdentifier = ruleIdentifier
        self.severity = severity
        self.title = title
        self.summary = summary
        self.affectedEndpoints = affectedEndpoints
        self.estimatedSavingBytes = estimatedSavingBytes
        self.howToFix = howToFix
    }
}

extension NetworkUsageHint {
    /// Warnings first, then the largest estimated saving, then by title.
    static func isOrderedBefore(_ lhs: NetworkUsageHint, _ rhs: NetworkUsageHint) -> Bool {
        if lhs.severity != rhs.severity {
            return lhs.severity > rhs.severity
        }
        let lhsSaving = lhs.estimatedSavingBytes ?? -1
        let rhsSaving = rhs.estimatedSavingBytes ?? -1
        if lhsSaving != rhsSaving {
            return lhsSaving > rhsSaving
        }
        return lhs.title < rhs.title
    }
}
