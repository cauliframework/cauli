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

internal class CauliViewController: UITableViewController {

    private class SubtitleTableViewCell: UITableViewCell {
        static let reuseIdentifier = "SubtitleTableViewCell"
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
    }

    private let cauli: Cauli
    private var displayingFlorets: [DisplayingFloret]
    private var interceptingFlorets: [InterceptingFloret]

    init(cauli: Cauli) {
        self.cauli = cauli

        displayingFlorets = cauli.florets.compactMap { $0 as? DisplayingFloret }
        interceptingFlorets = cauli.florets.compactMap { $0 as? InterceptingFloret }

        super.init(style: .grouped)
        title = "Cauli"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: SubtitleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: SwitchTableViewCell.nibName, bundle: Cauli.bundle), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return displayingFlorets.count
        }

        return interceptingFlorets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return self.tableView(tableView, detailCellForRowAt: indexPath)
        case 1: return self.tableView(tableView, switchCellForRowAt: indexPath)
        default: fatalError("we shouldn't reach this point")
        }
    }

    private func tableView(_ tableView: UITableView, detailCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let description = displayingFlorets[indexPath.row].description {
            cell = tableView.dequeueReusableCell(withIdentifier: SubtitleTableViewCell.reuseIdentifier, for: indexPath)
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.lineBreakMode = .byWordWrapping
            cell.detailTextLabel?.text = description
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
        cell.textLabel?.text = displayingFlorets[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func tableView(_ tableView: UITableView, switchCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.reuseIdentifier, for: indexPath) as? SwitchTableViewCell else { fatalError("we shouldn't reach this point") }

        var floret = interceptingFlorets[indexPath.row]
        cell.set(title: floret.name, switchValue: floret.enabled, description: floret.description)
        cell.switchValueChanged = {
            floret.enabled = $0
        }
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        navigationController?.pushViewController(displayingFlorets[indexPath.row].viewController(cauli), animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Displaying Florets"
        case 1: return "Intercepting Florets"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "If an InterceptingFloret is disabled it cannot intercept any requests or responses."
        default: return nil
        }
    }
}
