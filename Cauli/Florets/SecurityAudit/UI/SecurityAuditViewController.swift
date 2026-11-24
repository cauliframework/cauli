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

/// The findings of the SecurityAuditFloret: totals per severity, the findings and the ignored ones.
internal class SecurityAuditViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case totals
        case issues
        case ignored
    }

    let floret: SecurityAuditFloret
    private(set) var issues: [SecurityAuditIssue] = []
    private var ignoredCount = 0

    init(floret: SecurityAuditFloret) {
        self.floret = floret
        super.init(style: .insetGrouped)
        title = "Security Audit"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SecurityAuditTotalsCell.self, forCellReuseIdentifier: SecurityAuditTotalsCell.reuseIdentifier)
        tableView.register(SecurityAuditIssueCell.self, forCellReuseIdentifier: SecurityAuditIssueCell.reuseIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetTapped))
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        issues = floret.issues
        ignoredCount = floret.ignoredFindings.count
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

    func ignore(issueAt index: Int) {
        floret.ignore(issues[index])
        reload()
    }

    func showIssue(at index: Int) {
        navigationController?.pushViewController(SecurityAuditIssueViewController(floret: floret, issue: issues[index]), animated: true)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section) == .issues ? max(1, issues.count) : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section) == .issues ? "Findings" : nil
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .totals:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = Calendar.current.isDateInToday(floret.start) ? .none : .short
            let requests = floret.checkedRequests
            let hosts = floret.checkedHostCount
            return "\(requests) \(requests == 1 ? "request" : "requests") to \(hosts) \(hosts == 1 ? "host" : "hosts") checked since \(formatter.string(from: floret.start))."
        case .issues:
            return "Swipe left to ignore a finding for its endpoints. Values like tokens are masked. Only URLs and headers are checked, not bodies."
        case .ignored, nil:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .totals:
            let cell = tableView.dequeueReusableCell(withIdentifier: SecurityAuditTotalsCell.reuseIdentifier, for: indexPath)
            let counts = SecurityAuditSeverity.allCases.reversed().map { severity in (severity: severity, count: issues.filter { $0.severity == severity }.count) }
            (cell as? SecurityAuditTotalsCell)?.set(counts: counts)
            return cell
        case .issues:
            guard !issues.isEmpty else {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "No findings yet"
                cell.textLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.text = "Findings appear here as the app sends requests."
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: SecurityAuditIssueCell.reuseIdentifier, for: indexPath)
            (cell as? SecurityAuditIssueCell)?.set(issues[indexPath.row])
            return cell
        case .ignored:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Ignored"
            cell.detailTextLabel?.text = "\(ignoredCount)"
            cell.accessoryType = .disclosureIndicator
            return cell
        case nil:
            fatalError("there are only three sections")
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .issues where !issues.isEmpty:
            showIssue(at: indexPath.row)
        case .ignored:
            navigationController?.pushViewController(SecurityAuditIgnoredViewController(floret: floret), animated: true)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section) {
        case .issues: return !issues.isEmpty
        case .ignored: return true
        case .totals, nil: return false
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .issues, !issues.isEmpty else { return nil }
        let ignore = UIContextualAction(style: .destructive, title: "Ignore") { [weak self] _, _, completion in
            self?.ignore(issueAt: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [ignore])
    }
}
