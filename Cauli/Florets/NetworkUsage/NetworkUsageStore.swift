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

/// Collects the transfers of a `NetworkUsageFloret`. Thread safe, as florets are called on the
/// threads of the URL loading system and the UI reads on the main thread.
internal final class NetworkUsageStore {

    private let lock = NSLock()
    private let maximumTransfers: Int
    private var start: Date
    private var totals = NetworkUsageTotals()
    private var hosts: [String: HostUsage] = [:]
    private var endpoints: [String: EndpointUsage] = [:]
    private var transfers: [NetworkUsageTransfer] = []

    init(maximumTransfers: Int, start: Date = Date()) {
        self.maximumTransfers = max(1, maximumTransfers)
        self.start = start
    }

    func add(_ transfer: NetworkUsageTransfer) {
        lock.lock()
        defer { lock.unlock() }
        totals.add(transfer)
        hosts[transfer.host, default: HostUsage(host: transfer.host)].add(transfer)
        endpoints[transfer.endpointKey, default: EndpointUsage(host: transfer.host, method: transfer.method, path: transfer.endpoint)].totals.add(transfer)
        transfers.append(transfer)
        if transfers.count > maximumTransfers {
            transfers.removeFirst(transfers.count - maximumTransfers)
        }
    }

    func reset(start: Date = Date()) {
        lock.lock()
        defer { lock.unlock() }
        self.start = start
        totals = NetworkUsageTotals()
        hosts = [:]
        endpoints = [:]
        transfers = []
    }

    func snapshot() -> NetworkUsageSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return NetworkUsageSnapshot(start: start, totals: totals, hosts: Array(hosts.values), endpoints: Array(endpoints.values), transfers: transfers)
    }
}
