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

/// The network usage the `NetworkUsageFloret` recorded since it was created or reset.
/// Rules evaluate it to find hints.
public struct NetworkUsageSnapshot {

    /// When the recording started.
    public let start: Date

    /// The counts of all transfers.
    public let totals: NetworkUsageTotals

    /// The usage of each host, the most received bytes first.
    public let hosts: [HostUsage]

    /// The usage of each endpoint, the most received bytes first.
    public let endpoints: [EndpointUsage]

    /// The most recent transfers, the oldest first. The floret keeps a limited number of them,
    /// while the totals, hosts and endpoints count all transfers.
    public let transfers: [NetworkUsageTransfer]

    /// Creates a snapshot, e.g. for tests of custom rules.
    public init(start: Date, totals: NetworkUsageTotals, hosts: [HostUsage], endpoints: [EndpointUsage], transfers: [NetworkUsageTransfer]) {
        self.start = start
        self.totals = totals
        self.hosts = hosts.sorted { $0.totals.receivedBytes > $1.totals.receivedBytes }
        self.endpoints = endpoints.sorted { $0.totals.receivedBytes > $1.totals.receivedBytes }
        self.transfers = transfers
    }

    /// The median duration of the recent transfers over the network. `nil` without any.
    public var medianDuration: TimeInterval? {
        let durations = transfers
            .filter { !$0.metrics.isFromCache }
            .map(\.metrics.duration)
            .sorted()
        guard !durations.isEmpty else { return nil }
        return durations[durations.count / 2]
    }

    /// The endpoints with the given keys, in the order of `endpoints`.
    public func endpoints(withKeys keys: Set<String>) -> [EndpointUsage] {
        endpoints.filter { keys.contains($0.key) }
    }

    /// The endpoints of the given hosts, in the order of `endpoints`.
    public func endpoints(ofHosts hosts: Set<String>) -> [EndpointUsage] {
        endpoints.filter { hosts.contains($0.host) }
    }
}
