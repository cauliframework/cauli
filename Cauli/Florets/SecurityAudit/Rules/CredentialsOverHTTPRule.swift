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

/// Finds credentials sent over plain HTTP: `Authorization`, `Proxy-Authorization` or `Cookie` headers,
/// or a user and password in the URL. Requests to localhost are not reported.
public struct CredentialsOverHTTPRule: SecurityAuditRule {

    /// The header fields that carry credentials.
    public static let headerNames = ["Authorization", "Proxy-Authorization", "Cookie"]

    /// "credentials-over-http"
    public let identifier = "credentials-over-http"

    /// Creates the rule.
    public init() {}

    /// Reports a request over plain HTTP that carries credentials.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard exchange.isCleartext, !exchange.isLoopback, let url = exchange.url else { return [] }
        var lines: [String] = []
        var values: [String] = []
        for name in CredentialsOverHTTPRule.headerNames {
            if let value = exchange.requestHeader(name), !value.isEmpty {
                lines.append("\(name): \(value)")
                values.append(SecurityAuditRuleSupport.credential(in: value))
            }
        }
        if let password = url.password {
            lines.append(url.absoluteString)
            values.append(password)
        }
        guard !lines.isEmpty else { return [] }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .critical,
            title: "Credentials over HTTP",
            summary: "Credentials are sent unencrypted. Anyone on the same network can read and reuse them.",
            evidence: lines.joined(separator: "\n"),
            sensitiveValues: values,
            howToFix: "Use HTTPS for every request that carries credentials, or better, for all requests."
        )]
    }
}
