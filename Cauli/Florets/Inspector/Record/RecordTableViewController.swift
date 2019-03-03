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

internal class RecordTableViewController: UITableViewController {

    let record: Record
    let datasource: RecordTableViewDatasource
    lazy var shareButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped))
    }()

    init(_ record: Record) {
        self.record = record
        self.datasource = RecordTableViewDatasource(record)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Record"
        datasource.setup(tableView)
        tableView.dataSource = datasource
        navigationItem.rightBarButtonItem = shareButton
    }

    @objc func shareButtonTapped() {
        guard let tempPath = MockRecordSerializer.write(record: record) else { return }

        let allRecordFiles = (try? FileManager.default.contentsOfDirectory(at: tempPath, includingPropertiesForKeys: nil, options: [])) ?? []

        let viewContoller = UIActivityViewController(activityItems: allRecordFiles, applicationActivities: nil)
        present(viewContoller, animated: true, completion: nil)
    }

}

// UITableViewDelegate
extension RecordTableViewController {

    static let prettyPrinter: [PrettyPrinter.Type] = [PlaintextPrettyPrinter.self]

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = datasource.item(at: indexPath),
            let sourceCell = tableView.cellForRow(at: indexPath) else { return }

        presentActionSelection(for: item, from: sourceCell)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func presentActionSelection(for item: RecordTableViewDatasource.Item, from cell: UITableViewCell) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for prettyPrinter in RecordTableViewController.prettyPrinter {
            if let value = item.value(), let viewController = prettyPrinter.viewController(for: value) {
                alertController.addAction(UIAlertAction(title: prettyPrinter.name, style: .default) { [weak self] _ in
                    self?.navigationController?.pushViewController(viewController, animated: true)
                })
            }
        }

        alertController.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            let activityItem = item.value() ?? item.description
            self?.presentShareSheet(for: [activityItem], from: cell)
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func presentShareSheet(for items: [Any], from cell: UITableViewCell) {
        let viewContoller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        viewContoller.popoverPresentationController?.sourceView = cell
        viewContoller.popoverPresentationController?.sourceRect = cell.bounds
        viewContoller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        present(viewContoller, animated: true, completion: nil)
    }

}
