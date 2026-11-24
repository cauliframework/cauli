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

/// Finds requests over plain HTTP. Requests to localhost are not reported.
public struct CleartextHTTPRule: SecurityAuditRule {

    /// "cleartext-http"
    public let identifier = "cleartext-http"

    /// Creates the rule.
    public init() {}

    /// Reports a request over plain HTTP.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard exchange.isCleartext, !exchange.isLoopback, let url = exchange.url else { return [] }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Cleartext HTTP",
            summary: "The request is sent over plain HTTP. Anyone on the same network can read and change it.",
            evidence: url.absoluteString,
            sensitiveValues: SecurityAuditRuleSupport.queryValues(of: url),
            howToFix: "Use HTTPS. App Transport Security blocks plain HTTP unless the app allows it in its Info.plist, so check its exceptions too."
        )]
    }
}
