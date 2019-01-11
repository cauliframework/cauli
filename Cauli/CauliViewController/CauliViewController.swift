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

    private let cauli: Cauli
    private var viewControllers: [(viewController: UIViewController, floret: Floret)]

    init(cauli: Cauli) {
        self.cauli = cauli
        viewControllers = cauli.florets.compactMap {
            guard let viewController = $0.viewController(cauli) else { return nil }
            return (viewController, $0)
        }
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
        let bundle = Bundle(for: SwitchTableViewCell.self)
        tableView.register(UINib(nibName: SwitchTableViewCell.nibName, bundle: bundle), forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewControllers.count
        }

        return cauli.florets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return self.tableView(tableView, detailCellForRowAt: indexPath)
        case 1: return self.tableView(tableView, switchCellForRowAt: indexPath)
        default: fatalError("we shouldn't reach this point")
        }
    }

    private func tableView(_ tableView: UITableView, detailCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = viewControllers[indexPath.row].floret.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func tableView(_ tableView: UITableView, switchCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.reuseIdentifier, for: indexPath) as? SwitchTableViewCell else { fatalError("we shouldn't reach this point") }

        var floret = cauli.florets[indexPath.row]
        cell.titleLabel?.text = floret.name
        cell.switch.isOn = floret.enabled
        cell.switchValueChanged = {
            floret.enabled = $0
        }
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        navigationController?.pushViewController(viewControllers[indexPath.row].viewController, animated: true)
    }

}
