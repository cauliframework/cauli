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

/// Finds hosts reached only over HTTP/1.
public struct LegacyProtocolRule: NetworkUsageRule {

    /// "legacy-protocol"
    public let identifier = "legacy-protocol"

    /// Creates the rule.
    public init() {}

    /// Returns a hint if hosts only used HTTP/1.0 or HTTP/1.1.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let hosts = usage.hosts
            .filter { !$0.protocols.isEmpty && $0.protocols.allSatisfy { $0.lowercased().hasPrefix("http/1") } }
            .map(\.host)
        guard !hosts.isEmpty else { return nil }
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .info,
            title: "HTTP/1.1 only",
            summary: hosts.joined(separator: ", "),
            affectedEndpoints: usage.endpoints(ofHosts: Set(hosts)),
            estimatedSavingBytes: nil,
            howToFix: "Enable HTTP/2 or HTTP/3 on the server. They send many requests over one connection and compress header fields."
        )
    }
}
