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

/// Finds e-mail addresses and phone numbers sent to hosts other than the app's own, in the URL or a header.
/// The `SecurityAuditFloret` adds it when it is created with `firstPartyHosts`.
public struct ThirdPartyPersonalDataRule: SecurityAuditRule {

    /// "third-party-personal-data"
    public let identifier = "third-party-personal-data"

    /// The app's own hosts, e.g. ["example.com"], which includes their subdomains.
    public let firstPartyHosts: [String]

    /// Creates the rule.
    ///
    /// - Parameter firstPartyHosts: The app's own hosts, e.g. ["example.com"], which includes their subdomains.
    public init(firstPartyHosts: [String]) {
        self.firstPartyHosts = firstPartyHosts.map { $0.lowercased() }
    }

    /// Whether the host is one of the app's own or a subdomain of one.
    public func isFirstParty(_ host: String) -> Bool {
        firstPartyHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    /// Reports personal data sent to a third-party host.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard !firstPartyHosts.isEmpty, !exchange.isLoopback, let host = exchange.host, !isFirstParty(host), let url = exchange.url else { return [] }
        let headers = (exchange.request.allHTTPHeaderFields ?? [:]).sorted { $0.key < $1.key }
        let headerMatches = headers.flatMap { header in PersonalDataDetector.emails(in: header.value).map { (header, $0) } }
        let matches = PersonalDataDetector.matches(in: url) + headerMatches.map(\.1)
        guard !matches.isEmpty else { return [] }
        let evidence = [url.absoluteString.removingPercentEncoding ?? url.absoluteString] + headerMatches.map { "\($0.0.key): \($0.0.value)" }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Personal data to third parties",
            summary: "\(PersonalDataDetector.describe(matches)) \(matches.count == 1 ? "is" : "are") sent to \(host), which isn't one of the app's own hosts.",
            evidence: evidence.joined(separator: "\n"),
            sensitiveValues: matches.map(\.value),
            howToFix: "Check whether the third party needs this data, and mention it in the app's privacy details. Send a pseudonymous id instead where possible."
        )]
    }
}
