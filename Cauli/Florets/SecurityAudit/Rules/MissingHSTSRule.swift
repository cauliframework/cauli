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

/// Finds HTTPS hosts that don't send `Strict-Transport-Security`.
public struct MissingHSTSRule: SecurityAuditRule {

    /// "missing-hsts"
    public let identifier = "missing-hsts"

    /// Creates the rule.
    public init() {}

    /// Reports an HTTPS response without a `Strict-Transport-Security` header.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard exchange.isHTTPS, !exchange.isLoopback, exchange.response != nil, let host = exchange.host,
            exchange.responseHeader("Strict-Transport-Security") == nil else { return [] }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .info,
            title: "Missing HSTS",
            summary: "\(host) doesn't send Strict-Transport-Security, so browsers and web views may still try plain HTTP first.",
            evidence: "https://\(host) responded without Strict-Transport-Security",
            howToFix: "Send Strict-Transport-Security: max-age=31536000; includeSubDomains with every HTTPS response.",
            scope: .host
        )]
    }
}
