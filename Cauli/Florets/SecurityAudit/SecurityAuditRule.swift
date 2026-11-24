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

/// A rule checks one request and its response for one kind of privacy or security problem.
/// Every finding it returns is shown by the `SecurityAuditFloret`.
///
/// Rules see URLs and headers, not bodies. They are pure functions, so they are easy to test:
///
/// ```swift
/// struct InternalHostRule: SecurityAuditRule {
///     let identifier = "internal-host"
///     func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
///         guard let host = exchange.host, host.hasSuffix(".internal.example.com") else { return [] }
///         return [SecurityAuditFinding(ruleIdentifier: identifier, severity: .warning, title: "Internal hosts",
///                                      summary: "The app talks to an internal host.", evidence: host,
///                                      howToFix: "Use the public API host.", scope: .host)]
///     }
/// }
///
/// let floret = SecurityAuditFloret(rules: SecurityAuditFloret.defaultRules + [InternalHostRule()])
/// ```
public protocol SecurityAuditRule {

    /// Identifies the rule and its findings, e.g. "secrets-in-urls".
    var identifier: String { get }

    /// Returns the problems found in the exchange, an empty array if there are none.
    func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding]
}
