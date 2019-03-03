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

internal class InspectorTableViewDatasource: NSObject {

    internal private(set) var items: [Record] = [] {
        didSet {
            filteredItems = self.filteredItems(in: items, with: filter)
        }
    }
    internal private(set) var filteredItems: [Record] = []
    private var filter: RecordSelector? {
        didSet {
            filteredItems = self.filteredItems(in: items, with: filter)
        }
    }
    internal var filterString: String? {
        didSet {
            updateFilter(with: filterString)
        }
    }

    private func filteredItems(in array: [Record], with filter: RecordSelector?) -> [Record] {
        guard let filter = filter else { return array }
        return array.filter(filter.selects)
    }

    private func updateFilter(with filterString: String?) {
        guard let filterString = filterString, !filterString.isEmpty else {
            filter = nil
            return
        }
        filter = RecordSelector { record in
            guard let urlString = record.designatedRequest.url?.absoluteString else {
                return false
            }
            return urlString.range(of: filterString, options: String.CompareOptions.caseInsensitive) != nil
        }
    }

    private func filter(records: [Record]) -> [Record] {
        return filteredItems(in: records, with: filter)
    }

    private func performBatchUpdate(in tableView: UITableView, updates: (() -> Void), completion: ((_ finished: Bool) -> Void)? = nil) {
        if #available(iOS 11, *) {
            tableView.performBatchUpdates(updates, completion: completion)
        } else {
            tableView.beginUpdates()
            updates()
            tableView.endUpdates()
            completion?(true)
        }
    }

    internal func append(records: [Record], to tableView: UITableView, completion: ((_ finished: Bool) -> Void)? = nil) {
        performBatchUpdate(in: tableView, updates: {
            let numberOfExistingRecords = filteredItems.count
            let numberOfAddedRecords = filter(records: records).count
            let indexPaths = (numberOfExistingRecords..<(numberOfExistingRecords + numberOfAddedRecords)).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .bottom)
            items += records
        }, completion: completion)
    }

}

extension InspectorTableViewDatasource: UITableViewDataSource {
    internal func setup(tableView: UITableView) {
        tableView.dataSource = self
        let bundle = Bundle(for: InspectorTableViewController.self)
        let nib = UINib(nibName: InspectorRecordTableViewCell.nibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: InspectorRecordTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 82.0
    }

    internal func record(at indexPath: IndexPath) -> Record {
        return filteredItems[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InspectorRecordTableViewCell.reuseIdentifier, for: indexPath) as? InspectorRecordTableViewCell else {
            fatalError("Unable to dequeue a cell")
        }
        cell.configure(with: record(at: indexPath), stringToHighlight: filterString)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
