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

/// The usage of one host.
public struct HostUsage: Codable, Equatable {

    /// The host, e.g. "api.example.com".
    public let host: String

    /// The counts of all its transfers.
    public internal(set) var totals = NetworkUsageTotals()

    /// The protocols its responses used, e.g. ["h2"], sorted.
    public internal(set) var protocols: [String] = []

    /// Creates the usage of a host without transfers.
    public init(host: String) {
        self.host = host
    }

    mutating func add(_ transfer: NetworkUsageTransfer) {
        totals.add(transfer)
        if let networkProtocol = transfer.metrics.networkProtocol, !transfer.metrics.isFromCache, !protocols.contains(networkProtocol) {
            protocols.append(networkProtocol)
            protocols.sort()
        }
    }
}
