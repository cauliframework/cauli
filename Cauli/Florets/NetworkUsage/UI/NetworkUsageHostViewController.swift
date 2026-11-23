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

import UIKit

/// Shows the usage of one host and its endpoints, tagged with the hints about them.
internal class NetworkUsageHostViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case totals
        case endpoints
    }

    let host: HostUsage
    let endpoints: [EndpointUsage]
    private let hintTitlesByEndpoint: [String: [String]]
    private let medianDuration: TimeInterval?

    init(host: HostUsage, usage: NetworkUsageSnapshot, hints: [NetworkUsageHint]) {
        self.host = host
        self.endpoints = usage.endpoints(ofHosts: [host.host])
        var titles: [String: [String]] = [:]
        for hint in hints {
            for endpoint in hint.affectedEndpoints where endpoint.host == host.host {
                titles[endpoint.key, default: []].append(hint.title)
            }
        }
        self.hintTitlesByEndpoint = titles
        let durations = usage.transfers
            .filter { $0.host == host.host && !$0.metrics.isFromCache }
            .map(\.metrics.duration)
            .sorted()
        self.medianDuration = durations.isEmpty ? nil : durations[durations.count / 2]
        super.init(style: .insetGrouped)
        title = host.host
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var totalsRows: [(String, String)] {
        let totals = host.totals
        var rows = [
            ("Requests", "\(totals.requests)"),
            ("Received", NetworkUsageFormatting.bytes(totals.receivedBytes)),
            ("Sent", NetworkUsageFormatting.bytes(totals.sentBytes)),
            ("From cache", "\(totals.requestsFromCache)")
        ]
        if !host.protocols.isEmpty {
            rows.append(("Protocol", host.protocols.joined(separator: ", ")))
        }
        if let reuse = totals.connectionReuse {
            rows.append(("Connections reused", NetworkUsageFormatting.percent(reuse)))
        }
        if let duration = medianDuration {
            rows.append(("Median duration", NetworkUsageFormatting.duration(duration)))
        }
        return rows
    }

    /// The titles of the hints about the endpoint, e.g. ["Uncompressed responses"].
    func hintTitles(for endpoint: EndpointUsage) -> [String] {
        hintTitlesByEndpoint[endpoint.key] ?? []
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .totals: return totalsRows.count
        case .endpoints: return endpoints.count
        case nil: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section) == .endpoints ? "Endpoints · by data received" : nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section(rawValue: section) == .endpoints ? "Paths with ids are grouped, e.g. /users/42 and /users/43 count as /users/:id." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .totals:
            let row = totalsRows[indexPath.row]
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = row.0
            cell.detailTextLabel?.text = row.1
            cell.selectionStyle = .none
            return cell
        case .endpoints:
            let endpoint = endpoints[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = endpoint.name
            cell.textLabel?.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .regular)
            var details = [
                "\(NetworkUsageFormatting.bytes(endpoint.totals.receivedBytes)) received",
                NetworkUsageFormatting.count(endpoint.totals.requests, "request", "requests")
            ]
            let compression = endpoint.totals.decodedBodyBytes > endpoint.totals.receivedBodyBytes && endpoint.totals.receivedBodyBytes > 0
            if compression {
                details.append(String(format: "compressed %.1f×", Double(endpoint.totals.decodedBodyBytes) / Double(endpoint.totals.receivedBodyBytes)))
            }
            details += hintTitles(for: endpoint)
            cell.detailTextLabel?.text = details.joined(separator: " · ")
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        case nil:
            fatalError("there are only two sections")
        }
    }
}
