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

/// Picks the condition of a host, or the default condition if there is no host.
internal class NetworkConditionPickerViewController: UITableViewController {

    enum Section: Int, CaseIterable {
        case useDefault
        case presets
        case custom
    }

    let floret: NetworkConditionsFloret
    /// The host whose condition is picked, `nil` for the default.
    let host: String?
    let presets: [NetworkCondition]
    let customConditions: [NetworkCondition]

    init(floret: NetworkConditionsFloret, host: String?) {
        self.floret = floret
        self.host = host
        let presetNames = Set(NetworkCondition.presets.map(\.name))
        presets = floret.conditions.filter { presetNames.contains($0.name) }
        customConditions = floret.conditions.filter { !presetNames.contains($0.name) }
        super.init(style: .insetGrouped)
        title = host ?? "Default"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The selected condition, `nil` if the host uses the default.
    var selectedCondition: NetworkCondition? {
        guard let host = host else { return floret.defaultCondition }
        return floret.condition(for: host)
    }

    /// Selects the condition, `nil` makes the host use the default.
    func select(_ condition: NetworkCondition?) {
        if let host = host {
            floret.setCondition(condition, for: host)
        } else {
            floret.defaultCondition = condition ?? .noThrottling
        }
        tableView.reloadData()
    }

    func condition(at indexPath: IndexPath) -> NetworkCondition? {
        switch Section(rawValue: indexPath.section) {
        case .presets: return presets[indexPath.row]
        case .custom: return customConditions[indexPath.row]
        case .useDefault, nil: return nil
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .useDefault: return host == nil ? 0 : 1
        case .presets: return presets.count
        case .custom: return customConditions.count
        case nil: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .presets: return "Conditions"
        case .custom: return customConditions.isEmpty ? nil : "Custom"
        case .useDefault, nil: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .custom else { return nil }
        let delay = "Limits are simulated as a delay: Cauli hands each response to the app at once."
        return customConditions.isEmpty ? "Custom conditions are added in code. " + delay : delay
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        if let condition = condition(at: indexPath) {
            cell.textLabel?.text = condition.name
            cell.detailTextLabel?.text = NetworkConditionFormatting.details(condition)
            cell.accessoryType = selectedCondition?.name == condition.name ? .checkmark : .none
        } else {
            cell.textLabel?.text = "Use the default"
            cell.detailTextLabel?.text = "Currently \(floret.defaultCondition.name)"
            cell.accessoryType = selectedCondition == nil ? .checkmark : .none
        }
        if cell.accessoryType == .checkmark {
            cell.accessibilityTraits.insert(.selected)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        select(condition(at: indexPath))
    }
}
