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

/// Finds cookies set without `Secure` (a warning), `HttpOnly` or `SameSite` (info).
/// Cookies set by localhost are not reported.
public struct InsecureCookieRule: SecurityAuditRule {

    /// "insecure-cookies"
    public let identifier = "insecure-cookies"

    /// Creates the rule.
    public init() {}

    /// Reports the cookies of the response that miss an attribute, one finding per attribute.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard !exchange.isLoopback, let url = exchange.url, let fields = exchange.response?.allHeaderFields as? [String: String] else { return [] }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
        guard !cookies.isEmpty else { return [] }
        return [
            finding(cookies.filter { !$0.isSecure }, attribute: "Secure", severity: .warning,
                    why: "The browser engine also sends them over plain HTTP, where anyone on the same network can read them."),
            finding(cookies.filter { !$0.isHTTPOnly }, attribute: "HttpOnly", severity: .info,
                    why: "Scripts in web views can read them, e.g. after a cross-site scripting attack."),
            finding(cookies.filter { $0.sameSitePolicy == nil }, attribute: "SameSite", severity: .info,
                    why: "They are also sent with requests from other sites, which helps cross-site request forgery.")
        ].compactMap { $0 }
    }

    private func finding(_ cookies: [HTTPCookie], attribute: String, severity: SecurityAuditSeverity, why: String) -> SecurityAuditFinding? {
        guard !cookies.isEmpty else { return nil }
        let names = cookies.map(\.name).joined(separator: ", ")
        return SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: severity,
            title: "Cookies without \(attribute)",
            summary: "\(names) \(cookies.count == 1 ? "is" : "are") set without \(attribute). \(why)",
            evidence: cookies.map { "Set-Cookie: \($0.name)=\($0.value)" }.joined(separator: "\n"),
            sensitiveValues: cookies.map(\.value),
            howToFix: "Add the \(attribute) attribute when the server sets the \(cookies.count == 1 ? "cookie" : "cookies")."
        )
    }
}
