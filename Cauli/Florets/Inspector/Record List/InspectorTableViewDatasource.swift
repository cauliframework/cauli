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
            filteredItems = self.items.filter(self.filter.selects)
        }
    }
    internal private(set) var filteredItems: [Record] = []
    internal var filterString: String? {
        didSet {
            filteredItems = self.items.filter(self.filter.selects)
        }
    }
    private var filter: RecordSelector {
        guard let filterString = filterString, !filterString.isEmpty else {
            return RecordSelector { _ in true }
        }
        return RecordSelector { record in
            self.formatter.recordMatchesQuery(record: record, query: filterString)
        }
    }

    private let formatter: InspectorFloretFormatterType

    init(formatter: InspectorFloretFormatterType) {
        self.formatter = formatter
        super.init()
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
            let numberOfAddedRecords = records.filter(filter.selects).count
            let indexPaths = (numberOfExistingRecords..<(numberOfExistingRecords + numberOfAddedRecords)).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: .bottom)
            items += records
        }, completion: completion)
    }

}

extension InspectorTableViewDatasource: UITableViewDataSource {
    internal func setup(tableView: UITableView) {
        tableView.dataSource = self
        let nib = UINib(nibName: InspectorRecordTableViewCell.nibName, bundle: Cauli.bundle)
        tableView.register(nib, forCellReuseIdentifier: InspectorRecordTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 82.0
    }

    internal func record(at indexPath: IndexPath) -> Record {
        filteredItems[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InspectorRecordTableViewCell.reuseIdentifier, for: indexPath) as? InspectorRecordTableViewCell else {
            fatalError("Unable to dequeue a cell")
        }
        let data = formatter.listFormattedData(for: record(at: indexPath))
        cell.configure(with: data, stringToHighlight: filterString)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
