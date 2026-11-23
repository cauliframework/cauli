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

/// Finds hosts for which many requests opened a new connection.
public struct ConnectionReuseRule: NetworkUsageRule {

    /// "connection-reuse"
    public let identifier = "connection-reuse"

    /// The share of requests that should reuse an open connection, from 0 to 1.
    public var minimumReuse: Double

    /// Hosts with fewer network requests are ignored.
    public var minimumRequests: Int

    /// Creates the rule.
    public init(minimumReuse: Double = 0.8, minimumRequests: Int = 10) {
        self.minimumReuse = minimumReuse
        self.minimumRequests = minimumRequests
    }

    /// Returns a hint if hosts reused too few connections.
    public func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let hosts = usage.hosts.filter { host in
            host.totals.networkRequests >= minimumRequests && (host.totals.connectionReuse ?? 1) < minimumReuse
        }
        guard let first = hosts.first else { return nil }
        let summary = hosts.count == 1
            ? "\(first.host): \(NetworkUsageRuleSupport.count(first.totals.newConnections, "new connection", "new connections")) for \(first.totals.networkRequests) requests"
            : "\(hosts.count) hosts open many new connections"
        return NetworkUsageHint(
            ruleIdentifier: identifier,
            severity: .info,
            title: "Few connections reused",
            summary: summary,
            affectedEndpoints: usage.endpoints(ofHosts: Set(hosts.map(\.host))),
            estimatedSavingBytes: nil,
            howToFix: "Use one URLSession for all requests instead of creating new sessions, and make sure the server keeps connections alive."
        )
    }
}
