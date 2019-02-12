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

internal class InspectorTableViewController: UITableViewController {

    private static let recordPageSize = 20

    var cauli: Cauli
    var records: [Record] = []

    let searchController = UISearchController(searchResultsController: nil)
    var filteredRecords: [Record]?

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
        title = "Records"
        let bundle = Bundle(for: InspectorTableViewController.self)
        let nib = UINib(nibName: InspectorRecordTableViewCell.nibName, bundle: bundle)
        tableView.register(nib, forCellReuseIdentifier: InspectorRecordTableViewCell.reuseIdentifier)
        definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        records = cauli.storage.records(InspectorTableViewController.recordPageSize, after: nil)
        searchController.searchBar.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.searchBar.isHidden = true
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredRecords = filteredRecords {
            return filteredRecords.count
        }
        return records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InspectorRecordTableViewCell.reuseIdentifier, for: indexPath) as? InspectorRecordTableViewCell else {
            fatalError("Unable to dequeue a cell")
        }
        let record: Record
        if let filteredRecords = filteredRecords {
            record = filteredRecords[indexPath.row]
        } else {
            record = records[indexPath.row]
        }
        cell.record = record
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let record: Record
        if let filteredRecords = filteredRecords {
            record = filteredRecords[indexPath.row]
        } else {
            record = records[indexPath.row]
        }
        let recordTableViewController = RecordTableViewController(record)
        navigationController?.pushViewController(recordTableViewController, animated: true)
    }

    private var scrolledToEnd = false
    private var isLoading = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceToBottom = scrollView.contentSize.height - scrollView.frame.height - scrollView.contentOffset.y
        guard !scrolledToEnd, !isLoading, distanceToBottom < 100, filteredRecords == nil else { return }
        isLoading = true
        let newRecords = cauli.storage.records(InspectorTableViewController.recordPageSize, after: records.last)
        if newRecords.isEmpty {
            isLoading = false
            scrolledToEnd = true
        } else if #available(iOS 11, *) {
            tableView.performBatchUpdates({
                let indexPaths = (records.count..<(records.count + newRecords.count)).map { IndexPath(row: $0, section: 0) }
                tableView.insertRows(at: indexPaths, with: .bottom)
                records.append(contentsOf: newRecords)
            }, completion: { [weak self] _ in
                self?.isLoading = false
            })
        } else {
            let indexPaths = (records.count..<(records.count + newRecords.count)).map { IndexPath(row: $0, section: 0) }
            tableView.beginUpdates()
            tableView.insertRows(at: indexPaths, with: .bottom)
            records.append(contentsOf: newRecords)
            tableView.endUpdates()
            self.isLoading = false
        }
    }

}

// MARK: - UISearchResultsUpdating

extension InspectorTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let strippedSearch = searchController.searchBar.text!.trimmingCharacters(in: CharacterSet.whitespaces)
        let searchItems = strippedSearch.components(separatedBy: " ") as [String]
        guard searchItems.first?.isEmpty == false else {
            filteredRecords = nil
            return
        }
        filteredRecords = records.filter { record in
            guard let urlString = record.designatedRequest.url?.absoluteString else {
                return false
            }
            for item in searchItems {
                if urlString.range(of: item, options: String.CompareOptions.caseInsensitive) != nil {
                    return true
                }
            }
            return false
        }
        tableView.reloadData()
    }

}

// MARK: - UISearchBarDelegate

extension InspectorTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filteredRecords = nil
        tableView.reloadData()
    }

}
