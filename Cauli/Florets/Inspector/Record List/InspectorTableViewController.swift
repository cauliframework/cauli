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
    let dataSource = InspectorTableViewDatasource()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        return searchController
    }()

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
        dataSource.setup(tableView: tableView)
        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if dataSource.items.isEmpty {
            let records = cauli.storage.records(InspectorTableViewController.recordPageSize, after: dataSource.items.last)
            dataSource.append(records: records, to: tableView)
        }
        searchController.searchBar.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.searchBar.isHidden = true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let record = dataSource.record(at: indexPath)
        let recordTableViewController = RecordTableViewController(record)
        navigationController?.pushViewController(recordTableViewController, animated: true)
    }

    private var scrolledToEnd = false
    private var isLoading = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        loadAdditionalRecordsIfNeeded()
    }

    fileprivate func loadAdditionalRecordsIfNeeded() {
        let distanceToBottom = tableView.contentSize.height - tableView.frame.height - tableView.contentOffset.y
        guard !scrolledToEnd, !isLoading, distanceToBottom < 100 else { return }
        isLoading = true
        let newRecords = cauli.storage.records(InspectorTableViewController.recordPageSize, after: dataSource.items.last)
        guard !newRecords.isEmpty  else {
            isLoading = false
            scrolledToEnd = true
            return
        }

        dataSource.append(records: newRecords, to: tableView) { [weak self] _ in
            self?.isLoading = false
        }
    }
}

// MARK: - UISearchResultsUpdating

extension InspectorTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text ?? ""
        dataSource.filterString = searchString
        tableView.reloadData()
        loadAdditionalRecordsIfNeeded()
    }

}

// MARK: - UISearchBarDelegate

extension InspectorTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dataSource.filterString = nil
        tableView.reloadData()
    }

}
