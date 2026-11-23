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

/// The NetworkUsageFloret measures how much the app uses the network and suggests how to use less:
/// the bytes sent and received, compression, caching, protocols and connection reuse,
/// per host and per endpoint.
///
/// It counts from the moment it is created until `reset()`. Every `NetworkUsageRule` it is
/// created with is evaluated on the recorded usage, and each finding is shown as a hint.
///
/// ```swift
/// let usage = NetworkUsageFloret()
/// let cauli = Cauli([InspectorFloret(), usage])
/// cauli.run()
/// …
/// usage.snapshot.totals.receivedBytes
/// usage.hints.map(\.title)
/// ```
///
/// Only requests Cauli intercepts are counted. Requests the `RecordSelector` excludes, or that
/// are passed through because they exceed its limit, are missing.
public class NetworkUsageFloret: InterceptingFloret {

    /// The rules every NetworkUsageFloret uses unless it is created with others.
    public static var defaultRules: [NetworkUsageRule] {
        [
            UncompressedResponseRule(),
            DuplicateRequestRule(),
            NotCacheableRule(),
            UncompressedUploadRule(),
            LargePayloadRule(),
            LegacyProtocolRule(),
            ConnectionReuseRule()
        ]
    }

    /// If the floret is disabled, it doesn't count any requests.
    public var enabled = true

    /// The description shown in the Cauli menu.
    public var description: String? = "Measures how much the app uses the network and suggests how to use less."

    /// The rules evaluated to find hints.
    public let rules: [NetworkUsageRule]

    private let store: NetworkUsageStore

    /// Creates the floret.
    ///
    /// - Parameters:
    ///   - rules: The rules evaluated to find hints. Add your own to `defaultRules`.
    ///   - maximumTransfers: How many of the most recent transfers are kept for the rules and the export.
    ///     The totals, hosts and endpoints count all transfers.
    public init(rules: [NetworkUsageRule] = NetworkUsageFloret.defaultRules, maximumTransfers: Int = 10_000) {
        self.rules = rules
        self.store = NetworkUsageStore(maximumTransfers: maximumTransfers)
    }

    /// The usage recorded since the floret was created or reset.
    public var snapshot: NetworkUsageSnapshot {
        store.snapshot()
    }

    /// The hints of all rules for the recorded usage, warnings and the largest savings first.
    public var hints: [NetworkUsageHint] {
        hints(for: snapshot)
    }

    /// The hints of all rules for the given usage, warnings and the largest savings first.
    public func hints(for usage: NetworkUsageSnapshot) -> [NetworkUsageHint] {
        rules
            .compactMap { $0.evaluate(usage) }
            .sorted(by: NetworkUsageHint.isOrderedBefore)
    }

    /// Forgets the recorded usage and starts counting again.
    public func reset() {
        store.reset()
    }

    /// Passes the record on unchanged.
    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        completionHandler(record)
    }

    /// Counts the transfer of the record, if it was performed over the network, and passes it on unchanged.
    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        if let transfer = NetworkUsageTransfer(record) {
            store.add(transfer)
        }
        completionHandler(record)
    }
}

// MARK: - Export

extension NetworkUsageFloret {

    private struct Export: Encodable {
        let start: Date
        let totals: NetworkUsageTotals
        let hosts: [HostUsage]
        let endpoints: [EndpointUsage]
        let transfers: [NetworkUsageTransfer]
    }

    /// The recorded usage as JSON: totals, hosts, endpoints and the most recent transfers.
    public func exportJSON() throws -> Data {
        let usage = snapshot
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Export(start: usage.start, totals: usage.totals, hosts: usage.hosts, endpoints: usage.endpoints, transfers: usage.transfers))
    }

    /// The most recent transfers as CSV, one line per transfer.
    public func exportCSV() -> String {
        let dateFormatter = ISO8601DateFormatter()
        let header = "date,method,host,endpoint,url,status,sent bytes,received bytes,received body bytes,decoded body bytes,content type,content encoding,from cache,protocol,reused connection,duration"
        let lines = snapshot.transfers.map { transfer -> String in
            let metrics = transfer.metrics
            let fields: [String] = [
                dateFormatter.string(from: transfer.date),
                transfer.method,
                transfer.host,
                transfer.endpoint,
                transfer.url,
                transfer.statusCode.map(String.init) ?? "",
                String(metrics.sentBytes),
                String(metrics.receivedBytes),
                String(metrics.responseBodyBytes),
                String(metrics.responseBodyBytesDecoded),
                transfer.responseContentType ?? "",
                transfer.responseContentEncoding ?? "",
                String(metrics.isFromCache),
                metrics.networkProtocol ?? "",
                String(metrics.isReusedConnection),
                String(format: "%.3f", metrics.duration)
            ]
            return fields.map(NetworkUsageFloret.csvField).joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    /// Quotes a field that contains a comma, quote or line break.
    static func csvField(_ value: String) -> String {
        let needsQuotes = value.contains { [",", "\"", "\n", "\r"].contains($0) }
        guard needsQuotes else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
