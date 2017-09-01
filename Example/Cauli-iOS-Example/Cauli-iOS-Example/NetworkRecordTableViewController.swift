//
//  NetworkRecordTableViewController.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 22.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit
import Cauli

class NetworkRecordTableViewController: UITableViewController {

    var networkRecord: NetworkRecord?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return networkRecord == nil ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = self.identifier(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        if let cell = cell as? URLandHeadersTableViewCell {
            switch indexPath.row {
            case 0:
                cell.titleLabel?.text = "Original Request:"
                cell.set(request: networkRecord?.originalRequest)
            case 1:
                cell.titleLabel?.text = "Request:"
                cell.set(request: networkRecord?.request)
            case 2:
                cell.titleLabel?.text = "Response:"
                cell.set(response: networkRecord?.response)
            default: break
            }
        } else if let cell = cell as? DataTableViewCell,
            let data = networkRecord?.data,
            let dataString = String(data: data, encoding: .utf8) {
            let index = dataString.index(dataString.startIndex, offsetBy: min(dataString.characters.count, 4080))
            cell.dataLabel.text = dataString.substring(to: index)
        } else if let cell = cell as? DataTableViewCell {
            cell.dataLabel.text = ""
        } else {
            let extended = networkRecord as? ExtendedNetworkRecord
            switch indexPath.row {
            case 3:
                cell.textLabel?.text = "Metrics:"
                cell.detailTextLabel?.text = extended?.metrics?.description
            case 4:
                cell.textLabel?.text = "Error:"
                cell.detailTextLabel?.text = string(for: networkRecord?.error)
            default:
                break
            }
        }
        return cell
    }
    
    private func string(for error: Error?) -> String {
        if let error = error as? String {
            return error
        }
        
        return "-"
    }
    
    private func identifier(for indexPath: IndexPath) -> String {
        switch indexPath.row {
        case 0, 1, 2:
            return "URLandHeader"
        case 5:
            return "Data"
        default:
            return "subtitle"
        }
    }
}
