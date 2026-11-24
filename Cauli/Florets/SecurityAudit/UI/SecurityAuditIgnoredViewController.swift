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

/// The findings ignored for an endpoint, each with a button to report it again.
internal class SecurityAuditIgnoredViewController: UITableViewController {

    let floret: SecurityAuditFloret
    private(set) var ignored: [SecurityAuditIgnoredFinding] = []

    init(floret: SecurityAuditFloret) {
        self.floret = floret
        super.init(style: .insetGrouped)
        title = "Ignored"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    func reload() {
        ignored = floret.ignoredFindings
        tableView.reloadData()
    }

    func stopIgnoring(at index: Int) {
        floret.stopIgnoring(ignored[index])
        reload()
    }

    @objc private func stopIgnoringTapped(_ sender: UIButton) {
        stopIgnoring(at: sender.tag)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(1, ignored.count)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "An ignored finding stays hidden for its endpoints, also across app starts. New endpoints with the same problem are still reported."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.detailTextLabel?.textColor = .secondaryLabel
        guard !ignored.isEmpty else {
            cell.textLabel?.text = "Nothing ignored"
            cell.textLabel?.textColor = .secondaryLabel
            cell.detailTextLabel?.text = "Swipe left on a finding to ignore it."
            return cell
        }
        let finding = ignored[indexPath.row]
        cell.textLabel?.text = finding.title
        cell.detailTextLabel?.text = finding.endpoint
        cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .regular)
        cell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle
        let button = UIButton(type: .system)
        button.setTitle("Stop Ignoring", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.tag = indexPath.row
        button.addTarget(self, action: #selector(stopIgnoringTapped(_:)), for: .touchUpInside)
        button.sizeToFit()
        button.frame.size.height = max(button.frame.height, 44)
        cell.accessoryView = button
        return cell
    }
}
