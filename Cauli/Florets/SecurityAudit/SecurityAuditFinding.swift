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

/// One problem a `SecurityAuditRule` found in one request.
/// The `SecurityAuditFloret` groups the findings of a rule with the same title by endpoint.
public struct SecurityAuditFinding: Equatable {

    /// What the finding is grouped by.
    public enum Scope: Equatable {
        /// The method, host and path, e.g. "GET api.example.com/users/:id".
        case endpoint
        /// The host, e.g. for a missing header the server sends for all its responses.
        case host
    }

    /// The identifier of the rule that found it.
    public var ruleIdentifier: String

    /// How serious the finding is.
    public var severity: SecurityAuditSeverity

    /// A short title, e.g. "Secrets in URLs". Findings of a rule with the same title are grouped.
    public var title: String

    /// What was found and why it matters.
    public var summary: String

    /// An example of the problem, e.g. the URL or header. Shown masked.
    public var evidence: String

    /// The values in the evidence that are masked in the Cauli menu, e.g. a token.
    public var sensitiveValues: [String]

    /// How to fix the problem.
    public var howToFix: String

    /// What the finding is grouped by.
    public var scope: Scope

    /// Creates a finding.
    public init(ruleIdentifier: String, severity: SecurityAuditSeverity, title: String, summary: String, evidence: String, sensitiveValues: [String] = [], howToFix: String, scope: Scope = .endpoint) {
        self.ruleIdentifier = ruleIdentifier
        self.severity = severity
        self.title = title
        self.summary = summary
        self.evidence = evidence
        self.sensitiveValues = sensitiveValues
        self.howToFix = howToFix
        self.scope = scope
    }

    /// The evidence with every sensitive value masked, e.g. "access_token=eyJh•••".
    public var maskedEvidence: String {
        sensitiveValues
            .filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }
            .reduce(evidence) { $0.replacingOccurrences(of: $1, with: SecurityAuditFinding.mask($1)) }
    }

    /// Keeps the first characters of the value, at most 4 and a third of it, e.g. "eyJh•••".
    static func mask(_ value: String) -> String {
        String(value.prefix(min(4, value.count / 3))) + "•••"
    }
}
