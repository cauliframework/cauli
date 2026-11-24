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

/// Finds secrets in query parameters, e.g. `access_token`, `api_key`, `password` or `session`.
public struct SecretsInURLRule: SecurityAuditRule {

    /// The parameter names that hold a secret, lowercased. Names ending in "token" or "secret" are reported too.
    public static let defaultParameterNames: Set<String> = [
        "token", "access_token", "refresh_token", "id_token", "auth", "auth_token", "jwt",
        "api_key", "apikey", "api-key", "password", "passwd", "pwd", "secret", "client_secret",
        "session", "sessionid", "session_id", "sid"
    ]

    /// "secrets-in-urls"
    public let identifier = "secrets-in-urls"

    /// The parameter names that hold a secret, lowercased.
    public let parameterNames: Set<String>

    /// Creates the rule.
    ///
    /// - Parameter parameterNames: The parameter names that hold a secret, lowercased.
    public init(parameterNames: Set<String> = SecretsInURLRule.defaultParameterNames) {
        self.parameterNames = parameterNames
    }

    /// Reports a URL with secrets in its query.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard let url = exchange.url else { return [] }
        let items = (URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []).filter { item in
            let name = item.name.lowercased()
            let isSecret = parameterNames.contains(name) || name.hasSuffix("token") || name.hasSuffix("secret")
            return isSecret && !(item.value ?? "").isEmpty
        }
        guard !items.isEmpty else { return [] }
        let names = items.map(\.name).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Secrets in URLs",
            summary: "\(names.joined(separator: ", ")) \(names.count == 1 ? "is" : "are") sent in the URL. URLs end up in server logs, proxies, crash reports and analytics.",
            evidence: url.absoluteString,
            sensitiveValues: items.compactMap(\.value),
            howToFix: "Send secrets in a header, e.g. Authorization, or in the body of a POST request."
        )]
    }
}
