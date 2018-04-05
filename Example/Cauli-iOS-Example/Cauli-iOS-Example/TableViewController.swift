//
//  ViewController.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 20.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit
import Cauli

struct RequestItem {
    let title: String
    let request: URLRequest
}

class TableViewController: UITableViewController {
    
    let requests: [URLRequest] = [
        URLRequest(url: URL(string: "https://www.htw-berlin.de")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        URLRequest(url: URL(string: "https://www.f3.htw-berlin.de")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        URLRequest(url: URL(string: "https://www.f2.htw-berlin.de")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        URLRequest(url: URL(string: "https://www.google.de")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        URLRequest(url: URL(string: "https://www.facebook.com")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        URLRequest(url: URL(string: "https://lsf.htw-berlin.de")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20),
        {
            var request = URLRequest(url: URL(string: "https://json-in-http-header-test.com")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            return request
        }()
    ]
    
    var useCauli = true
    
    var _session: URLSession?
    var session: URLSession {
        get {
            if let s = _session {
                return s
            }
            _session = URLSession(configuration: URLSessionConfiguration.default)
            return _session!
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Test Applikation"
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let request = requests[indexPath.row]
            let started = Date()
            let task = session.dataTask(with: request) { (data, response, error) in
                print("\(request) - \(Date().timeIntervalSince(started))")

//                if let data = data {
//                    print(data)
//                }
//                
//                if let response = response {
//                    print(response)
//                }
//                
//                if let error = error {
//                    print(error)
//                }
            }
            task.resume()
        } else {
            if indexPath.row == 0 {
                performSegue(withIdentifier: "memory", sender: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Requests:"
        case 1:
            return "Debug:"
        default:
            return nil
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 7
        case 1:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, _):
            return self.tableView(tableView, requestCellForIndexPath: indexPath)
        case (1, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
            cell.textLabel?.text = "MemoryStorage"
            return cell
        case (1, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath)
            if let cell = cell as? SwitchTableViewCell {
                cell.titleLabel.text = "Enable Prototyp"
                cell.switchTriggered = { on in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if (on) {
                        appDelegate.cauli.adapter.enable()
                    } else {
                        appDelegate.cauli.adapter.disable()
                    }
                }
            }
            return cell
        default:
            fatalError("-.-")
        }
    }
    
    func tableView(_ tableView: UITableView, requestCellForIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        cell.textLabel?.text = requests[indexPath.row].url?.absoluteString
        return cell
    }
}
