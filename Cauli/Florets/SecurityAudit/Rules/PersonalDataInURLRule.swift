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

/// Finds e-mail addresses and phone numbers in URLs.
public struct PersonalDataInURLRule: SecurityAuditRule {

    /// "personal-data-in-urls"
    public let identifier = "personal-data-in-urls"

    /// Creates the rule.
    public init() {}

    /// Reports a URL with personal data in its path or query.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard let url = exchange.url else { return [] }
        let matches = PersonalDataDetector.matches(in: url)
        guard !matches.isEmpty else { return [] }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Personal data in URLs",
            summary: "\(PersonalDataDetector.describe(matches)) \(matches.count == 1 ? "is" : "are") part of the URL. URLs end up in server logs, proxies, crash reports and analytics.",
            evidence: url.absoluteString.removingPercentEncoding ?? url.absoluteString,
            sensitiveValues: matches.map(\.value),
            howToFix: "Identify users by an opaque id, and send personal data in the body of a POST request."
        )]
    }
}
