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

class InspectorTableViewDatasource: NSObject {

    typealias Filter = (Record) -> (Bool)

    public private(set) var items: [Record] = [] {
        didSet {
            filteredItems = self.filteredItems(in: items, with: filter)
        }
    }
    public private(set) var filteredItems: [Record] = []
    var filter: Filter? {
        didSet {
            filteredItems = self.filteredItems(in: items, with: filter)
        }
    }

    private func filteredItems(in array: [Record], with filter: Filter?) -> [Record] {
        guard let filter = filter else { return array }
        return array.filter(filter)
    }

    public func filter(records: [Record]) -> [Record] {
        return filteredItems(in: records, with: filter)
    }

    public func append(records: [Record]) {
        items += records
    }

}

extension InspectorTableViewDatasource: UITableViewDataSource {
    public func setup(tableView: UITableView) {
        tableView.dataSource = self
        let bundle = Bundle(for: InspectorTableViewController.self)
        let nib = UINib(nibName: InspectorRecordTableViewCell.nibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: InspectorRecordTableViewCell.reuseIdentifier)
    }

    public func record(at indexPath: IndexPath) -> Record {
        return filteredItems[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InspectorRecordTableViewCell.reuseIdentifier, for: indexPath) as? InspectorRecordTableViewCell else {
            fatalError("Unable to dequeue a cell")
        }
        cell.record = record(at: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
