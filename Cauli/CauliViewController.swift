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
    private var viewControllers: [IndexPath: UIViewController] = [:]

    init(cauli: Cauli) {
        self.cauli = cauli
        super.init(style: .plain)
        title = "Cauli"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cauli.florets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let floret = cauli.florets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let enabled = floret.enabled ? "✔️" : "" // ✔️☑️
        cell.textLabel?.text = floret.name + " " + enabled
        if viewController(for: floret, at: indexPath) == nil {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let floret = cauli.florets[indexPath.row]
        if let viewController = viewController(for: floret, at: indexPath) {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let floret = cauli.florets[indexPath.row]
        let actionTitle: String
        if floret.enabled {
            actionTitle = "Disable"
        } else {
            actionTitle = "Enable"
        }

        let toggleAction = UITableViewRowAction(style: .normal, title: actionTitle) { [weak self] _, indexPath in
            guard let strongSelf = self else { return }
            var floret = strongSelf.cauli.florets[indexPath.row]
            floret.enabled = !floret.enabled
            strongSelf.tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        return [toggleAction]
    }

    private func viewController(for floret: Floret, at indexPath: IndexPath) -> UIViewController? {
        if let cachedViewController = viewControllers[indexPath] {
            return cachedViewController
        }
        let newViewController = floret.viewController(cauli)
        viewControllers[indexPath] = newViewController
        return newViewController
    }

}
