//
//  MemoryTableViewController.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 22.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit
import Cauli

class MemoryTableViewController: UITableViewController {
    
    var memoryStorage: MemoryStorage? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return appDelegate.memoryStorage
    }
    
    var records: [NetworkRecord] {
        return memoryStorage?.records.reversed() ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    // MARK: - Table view data source
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "\(records.count) Einträge"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath)
        
        let record = records[indexPath.row]
        cell.textLabel?.text = record.originalRequest.url?.absoluteString
        cell.detailTextLabel?.text = record.request.url?.absoluteString
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "network", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? NetworkRecordTableViewController,
            let indexPath = tableView.indexPathForSelectedRow else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        vc.networkRecord = records[indexPath.row]
    }
}
