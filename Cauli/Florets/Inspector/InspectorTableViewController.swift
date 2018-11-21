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

class InspectorTableViewController: UITableViewController {

    private static let recordPageSize = 20
    
    var cauli: Cauli
    var records: [Record] = []

    init(_ cauli: Cauli) {
        self.cauli = cauli
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        records = cauli.storage.records(InspectorTableViewController.recordPageSize, after: nil)
        title = "Records"
        let bundle = Bundle(for: InspectorTableViewController.self)
        let nib = UINib(nibName: "InsectorRecordTableViewCell", bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: InsectorRecordTableViewCell.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InsectorRecordTableViewCell.reuseIdentifier, for: indexPath) as? InsectorRecordTableViewCell else {
            fatalError("Unable to dequeue a cell")
        }
        let record = records[indexPath.row]
        cell.record = record
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    private var scrolledToEnd = false
    private var isLoading = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceToBottom = scrollView.contentSize.height - scrollView.frame.height - scrollView.contentOffset.y
        guard !scrolledToEnd, !isLoading, distanceToBottom < 100 else { return }
        isLoading = true
        let newRecords = cauli.storage.records(InspectorTableViewController.recordPageSize, after: records.last)
        if newRecords.count > 0 {
            tableView.performBatchUpdates({
                let indexPaths = (records.count..<(records.count + newRecords.count)).map{ return IndexPath(row: $0, section: 0)
                }
                tableView.insertRows(at: indexPaths, with: .bottom)
                records.append(contentsOf: newRecords)
            }, completion: { [weak self] _ in
                self?.isLoading = false
            })
        } else {
            isLoading = false
            scrolledToEnd = true
        }
    }

}
