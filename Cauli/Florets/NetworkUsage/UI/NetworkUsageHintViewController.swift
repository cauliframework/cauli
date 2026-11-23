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

/// Shows one hint of the NetworkUsageFloret: what was found, the affected endpoints and how to fix it.
/// The same screen works for every rule, including custom ones.
internal class NetworkUsageHintViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case summary
        case endpoints
        case howToFix
    }

    let hint: NetworkUsageHint

    init(hint: NetworkUsageHint) {
        self.hint = hint
        super.init(style: .insetGrouped)
        title = hint.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var summaryRows: [(String, String)] {
        let received = hint.affectedEndpoints.reduce(Int64(0)) { $0 + $1.totals.receivedBytes }
        var rows = [("Received", NetworkUsageFormatting.bytes(received))]
        if let saving = hint.estimatedSavingBytes {
            rows.append(("Possible saving", NetworkUsageFormatting.estimate(saving)))
        }
        return rows
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .summary: return 1 + summaryRows.count
        case .endpoints: return hint.affectedEndpoints.count
        case .howToFix: return 1
        case nil: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .endpoints: return hint.affectedEndpoints.isEmpty ? nil : "Affected endpoints"
        case .howToFix: return "How to fix"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .summary, hint.estimatedSavingBytes != nil else { return nil }
        return "The saving is an estimate."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .summary where indexPath.row == 0:
            return textCell(hint.summary, font: .preferredFont(forTextStyle: .body))
        case .summary:
            let row = summaryRows[indexPath.row - 1]
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = row.0
            cell.detailTextLabel?.text = row.1
            cell.selectionStyle = .none
            return cell
        case .endpoints:
            let endpoint = hint.affectedEndpoints[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = endpoint.name
            cell.textLabel?.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .regular)
            cell.detailTextLabel?.text = "\(endpoint.host) · \(NetworkUsageFormatting.count(endpoint.totals.requests, "request", "requests")) · \(NetworkUsageFormatting.bytes(endpoint.totals.receivedBytes)) received"
            cell.detailTextLabel?.textColor = .secondaryLabel
            cell.selectionStyle = .none
            return cell
        case .howToFix:
            return textCell(hint.howToFix, font: .preferredFont(forTextStyle: .body))
        case nil:
            fatalError("there are only three sections")
        }
    }

    private func textCell(_ text: String, font: UIFont) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = text
        cell.textLabel?.font = font
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
}
