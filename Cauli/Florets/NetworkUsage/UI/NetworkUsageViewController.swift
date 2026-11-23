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

/// The overview of the NetworkUsageFloret: totals, hints and hosts.
internal class NetworkUsageViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case totals
        case hints
        case hosts
    }

    private let floret: NetworkUsageFloret
    private(set) var usage: NetworkUsageSnapshot
    private(set) var hints: [NetworkUsageHint]

    init(floret: NetworkUsageFloret) {
        self.floret = floret
        usage = floret.snapshot
        hints = floret.hints(for: usage)
        super.init(style: .insetGrouped)
        title = "Network Usage"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(NetworkUsageTotalsCell.self, forCellReuseIdentifier: NetworkUsageTotalsCell.reuseIdentifier)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetTapped)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped(_:)))
        ]
        navigationItem.rightBarButtonItems?.last?.accessibilityLabel = "Share as CSV or JSON"
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        usage = floret.snapshot
        hints = floret.hints(for: usage)
        tableView.reloadData()
    }

    @objc func resetTapped() {
        floret.reset()
        reload()
    }

    @objc private func refreshPulled() {
        reload()
        refreshControl?.endRefreshing()
    }

    @objc private func shareTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Share the network usage", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { [weak self] _ in
            self?.share(Data((self?.floret.exportCSV() ?? "").utf8), fileName: "network-usage.csv", from: sender)
        })
        alert.addAction(UIAlertAction(title: "JSON", style: .default) { [weak self] _ in
            guard let data = try? self?.floret.exportJSON() else { return }
            self?.share(data, fileName: "network-usage.json", from: sender)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.barButtonItem = sender
        present(alert, animated: true)
    }

    private func share(_ data: Data, fileName: String, from sender: UIBarButtonItem) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard (try? data.write(to: url)) != nil else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true)
    }

    // MARK: - Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .totals: return 1
        case .hints: return max(1, hints.count)
        case .hosts: return max(1, usage.hosts.count)
        case nil: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .totals: return NetworkUsageFormatting.since(usage.start)
        case .hints: return hints.isEmpty ? "Hints" : "Hints · \(hints.count)"
        case .hosts: return "Hosts · by data received"
        case nil: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .hosts else { return nil }
        return "Sizes are bytes over the network, after compression. Only requests Cauli intercepts are counted. Requests excluded by the RecordSelector are missing."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .totals:
            let cell = tableView.dequeueReusableCell(withIdentifier: NetworkUsageTotalsCell.reuseIdentifier, for: indexPath)
            (cell as? NetworkUsageTotalsCell)?.set(tiles: totalsTiles())
            return cell
        case .hints:
            return hints.isEmpty ? placeholderCell("No hints yet") : hintCell(hints[indexPath.row])
        case .hosts:
            return usage.hosts.isEmpty ? placeholderCell("No requests yet") : hostCell(usage.hosts[indexPath.row])
        case nil:
            fatalError("there are only three sections")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .hints where !hints.isEmpty:
            navigationController?.pushViewController(NetworkUsageHintViewController(hint: hints[indexPath.row]), animated: true)
        case .hosts where !usage.hosts.isEmpty:
            let host = usage.hosts[indexPath.row]
            navigationController?.pushViewController(NetworkUsageHostViewController(host: host, usage: usage, hints: hints), animated: true)
        default:
            return
        }
    }

    // MARK: - Cells

    private func totalsTiles() -> [NetworkUsageTotalsCell.Tile] {
        let totals = usage.totals
        let decoded = totals.decodedBodyBytes
        let savedShare = decoded > 0 ? NetworkUsageFormatting.percent(Double(totals.savedByCompression) / Double(decoded)) : "0%"
        return [
            .init(label: "Requests", value: "\(totals.requests)", detail: "\(totals.requestsFromCache) from cache"),
            .init(label: "Received", value: NetworkUsageFormatting.bytes(totals.receivedBytes), detail: "over the network"),
            .init(label: "Sent", value: NetworkUsageFormatting.bytes(totals.sentBytes), detail: "header fields and bodies"),
            .init(label: "Saved by compression", value: NetworkUsageFormatting.bytes(totals.savedByCompression), detail: "\(savedShare) of \(NetworkUsageFormatting.bytes(decoded)) decoded"),
            .init(label: "Median duration", value: usage.medianDuration.map(NetworkUsageFormatting.duration) ?? "–", detail: "of recent requests"),
            .init(label: "Connections reused", value: totals.connectionReuse.map(NetworkUsageFormatting.percent) ?? "–", detail: NetworkUsageFormatting.count(totals.newConnections, "new connection", "new connections"))
        ]
    }

    private func hintCell(_ hint: NetworkUsageHint) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = hint.title
        let saving = hint.estimatedSavingBytes.map { " · saves \(NetworkUsageFormatting.estimate($0))" } ?? ""
        cell.detailTextLabel?.text = hint.summary + saving
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        cell.imageView?.image = UIImage(systemName: hint.severity == .warning ? "exclamationmark.triangle.fill" : "info.circle")
        cell.imageView?.tintColor = hint.severity == .warning ? .systemOrange : .systemBlue
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func hostCell(_ host: HostUsage) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = host.host
        var details = [
            "\(NetworkUsageFormatting.bytes(host.totals.receivedBytes)) received",
            NetworkUsageFormatting.count(host.totals.requests, "request", "requests"),
            "\(NetworkUsageFormatting.bytes(host.totals.sentBytes)) sent"
        ]
        if host.totals.requestsFromCache > 0 {
            details.append("\(host.totals.requestsFromCache) from cache")
        }
        details += host.protocols
        cell.detailTextLabel?.text = details.joined(separator: " · ")
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func placeholderCell(_ text: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = text
        cell.textLabel?.textColor = .secondaryLabel
        cell.selectionStyle = .none
        return cell
    }
}
