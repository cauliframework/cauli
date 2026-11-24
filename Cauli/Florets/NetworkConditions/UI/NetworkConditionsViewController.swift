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

/// Lists the default condition, every remembered host with its condition, and a button that stops all throttling.
internal class NetworkConditionsViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case defaultCondition
        case hosts
        case stopAll
    }

    let floret: NetworkConditionsFloret
    private(set) var hosts: [String] = []

    init(floret: NetworkConditionsFloret) {
        self.floret = floret
        super.init(style: .insetGrouped)
        title = "Network Conditions"
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
        hosts = floret.hosts
        tableView.reloadData()
    }

    /// Opens the picker of the host's condition, or of the default if the host is `nil`.
    func showPicker(for host: String?) {
        let picker = NetworkConditionPickerViewController(floret: floret, host: host)
        navigationController?.pushViewController(picker, animated: true)
    }

    func forget(hostAt index: Int) {
        floret.forget(host: hosts[index])
        hosts.remove(at: index)
        if hosts.isEmpty {
            tableView.reloadSections(IndexSet(integer: Section.hosts.rawValue), with: .automatic)
        } else {
            tableView.deleteRows(at: [IndexPath(row: index, section: Section.hosts.rawValue)], with: .automatic)
        }
    }

    func stopAllThrottling() {
        floret.stopAllThrottling()
        reload()
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section) == .hosts ? max(hosts.count, 1) : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .defaultCondition: return "All other hosts"
        case .hosts: return "Hosts"
        case .stopAll, nil: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .defaultCondition: return "Applies to every host without its own condition."
        case .hosts: return "Every host the app connected to is remembered across app starts, the most recent first. Swipe left to forget a host."
        case .stopAll: return "Sets every host and the default to No throttling. The hosts stay in the list."
        case nil: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .defaultCondition:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let condition = floret.defaultCondition
            cell.textLabel?.text = "Default"
            cell.detailTextLabel?.text = condition.name
            cell.detailTextLabel?.textColor = condition.isThrottling ? NetworkConditionFormatting.throttlingColor : .secondaryLabel
            cell.accessoryType = .disclosureIndicator
            return cell
        case .hosts:
            guard !hosts.isEmpty else {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "No hosts yet"
                cell.textLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.text = "Hosts appear here once the app sends a request."
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.detailTextLabel?.numberOfLines = 0
                cell.selectionStyle = .none
                return cell
            }
            return hostCell(for: hosts[indexPath.row])
        case .stopAll:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Stop All Throttling"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemRed
            return cell
        case nil:
            fatalError("there are only three sections")
        }
    }

    private func hostCell(for host: String) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let ownCondition = floret.condition(for: host)
        cell.textLabel?.text = host
        cell.textLabel?.lineBreakMode = .byTruncatingMiddle
        cell.detailTextLabel?.text = ownCondition.map(NetworkConditionFormatting.details) ?? "Uses the default"
        cell.detailTextLabel?.textColor = .secondaryLabel

        let conditionLabel = UILabel()
        conditionLabel.font = .preferredFont(forTextStyle: .subheadline)
        conditionLabel.adjustsFontForContentSizeCategory = true
        if let condition = ownCondition, condition.isThrottling {
            conditionLabel.text = condition.name
            conditionLabel.textColor = NetworkConditionFormatting.throttlingColor
            conditionLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        } else {
            conditionLabel.text = ownCondition?.name ?? "Default"
            conditionLabel.textColor = .secondaryLabel
        }
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        chevron.tintColor = .tertiaryLabel
        let accessory = UIStackView(arrangedSubviews: [conditionLabel, chevron])
        accessory.spacing = 8
        accessory.alignment = .center
        accessory.frame.size = accessory.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        cell.accessoryView = accessory
        cell.accessibilityValue = conditionLabel.text
        cell.accessibilityTraits.insert(.button)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .defaultCondition:
            showPicker(for: nil)
        case .hosts where !hosts.isEmpty:
            showPicker(for: hosts[indexPath.row])
        case .stopAll:
            stopAllThrottling()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        Section(rawValue: indexPath.section) != .hosts || !hosts.isEmpty
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .hosts, !hosts.isEmpty else { return nil }
        let forget = UIContextualAction(style: .destructive, title: "Forget") { [weak self] _, _, completion in
            self?.forget(hostAt: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [forget])
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
