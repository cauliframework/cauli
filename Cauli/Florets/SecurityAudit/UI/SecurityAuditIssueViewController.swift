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

/// One finding: what it is, its endpoints, a masked example and how to fix it.
internal class SecurityAuditIssueViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case summary
        case endpoints
        case example
        case howToFix
        case ignore
    }

    let floret: SecurityAuditFloret
    let issue: SecurityAuditIssue
    private(set) var isRevealed = false

    init(floret: SecurityAuditFloret, issue: SecurityAuditIssue) {
        self.floret = floret
        self.issue = issue
        super.init(style: .insetGrouped)
        title = issue.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The evidence of the example, masked unless revealed.
    var exampleText: String {
        isRevealed ? issue.example.evidence : issue.example.maskedEvidence
    }

    /// Whether the example has values to mask.
    var canReveal: Bool {
        issue.example.maskedEvidence != issue.example.evidence
    }

    func toggleReveal() {
        isRevealed.toggle()
        tableView.reloadSections(IndexSet(integer: Section.example.rawValue), with: .none)
    }

    func ignoreTapped() {
        floret.ignore(issue)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .endpoints: return issue.endpoints.count
        case .example: return canReveal ? 2 : 1
        case .summary, .howToFix, .ignore: return 1
        case nil: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .endpoints: return issue.example.scope == .host ? "Hosts" : "Endpoints"
        case .example: return "Example"
        case .howToFix: return "How to fix"
        case .summary, .ignore, nil: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        let monospaced = UIFont.monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize, weight: .regular)
        switch Section(rawValue: indexPath.section) {
        case .summary:
            cell.textLabel?.text = issue.severity.name.uppercased()
            cell.textLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .bold)
            cell.textLabel?.textColor = SecurityAuditFormatting.color(of: issue.severity)
            cell.detailTextLabel?.text = issue.example.summary
            cell.detailTextLabel?.font = .preferredFont(forTextStyle: .body)
            cell.detailTextLabel?.textColor = .label
        case .endpoints:
            let endpoint = issue.endpoints[indexPath.row]
            cell.textLabel?.text = endpoint.name
            cell.textLabel?.font = monospaced
            cell.detailTextLabel?.text = SecurityAuditFormatting.details(of: endpoint)
        case .example where indexPath.row == 0:
            cell.textLabel?.text = exampleText
            cell.textLabel?.font = monospaced
            cell.textLabel?.lineBreakMode = .byCharWrapping
        case .example:
            return buttonCell(isRevealed ? "Hide Values" : "Reveal Values", color: tableView.tintColor)
        case .howToFix:
            cell.textLabel?.text = issue.example.howToFix
        case .ignore:
            return buttonCell("Ignore for These \(issue.example.scope == .host ? "Hosts" : "Endpoints")", color: .systemRed)
        case nil:
            break
        }
        return cell
    }

    private func buttonCell(_ title: String, color: UIColor) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = color
        cell.accessibilityTraits.insert(.button)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .example where indexPath.row == 1: toggleReveal()
        case .ignore: ignoreTapped()
        default: break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let section = Section(rawValue: indexPath.section)
        return section == .ignore || (section == .example && indexPath.row == 1)
    }
}
