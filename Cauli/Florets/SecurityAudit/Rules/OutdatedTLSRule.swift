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

/// Finds connections using a TLS version older than 1.2.
public struct OutdatedTLSRule: SecurityAuditRule {

    /// The versions reported, as `TransferMetrics.tlsVersion` names them.
    public static let outdatedVersions: Set<String> = ["SSL 3.0", "TLS 1.0", "TLS 1.1", "DTLS 1.0"]

    /// "outdated-tls"
    public let identifier = "outdated-tls"

    /// Creates the rule.
    public init() {}

    /// Reports a host that negotiated an outdated TLS version.
    public func evaluate(_ exchange: SecurityAuditExchange) -> [SecurityAuditFinding] {
        guard let version = exchange.tlsVersion, OutdatedTLSRule.outdatedVersions.contains(version), let host = exchange.host else { return [] }
        return [SecurityAuditFinding(
            ruleIdentifier: identifier,
            severity: .warning,
            title: "Outdated TLS",
            summary: "\(host) uses \(version), which has known weaknesses and is deprecated.",
            evidence: "\(host) negotiated \(version)",
            howToFix: "Enable TLS 1.2 or 1.3 on the server and disable older versions.",
            scope: .host
        )]
    }
}
