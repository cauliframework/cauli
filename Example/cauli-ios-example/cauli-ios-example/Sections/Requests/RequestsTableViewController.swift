//
//  ViewController.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 06.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import UIKit
import Cauliframework

class RequestsTableViewController: UITableViewController {
    
    lazy var urlSession: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    let requestModels: [RequestModel] = [
        RequestModel(name: "httpstat.us/200", url: URL(string: "https://httpstat.us/200")!),
        RequestModel(name: "httpstat.us/301", url: URL(string: "https://httpstat.us/301")!),
        RequestModel(name: "httpstat.us/304", url: URL(string: "https://httpstat.us/304")!),
        RequestModel(name: "httpstat.us/404", url: URL(string: "https://httpstat.us/404")!),
        RequestModel(name: "api.ipify.org", url: URL(string: "http://api.ipify.org/?format=json")!),
        RequestModel(name: "invalidurl.invalid", url: URL(string: "https://invalidurl.invalid/")!),
        RequestModel(name: "HTTP Basic Auth", url: URL(string: "https://jigsaw.w3.org/HTTP/Basic/")!),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(RequestModelTableViewCell.self, forCellReuseIdentifier: "RequestModelTableViewCell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestModels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestModelTableViewCell", for: indexPath)
        let requestModel = requestModels[indexPath.row]
        
        cell.textLabel?.text = requestModel.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let requestModel = requestModels[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        cell?.detailTextLabel?.text = nil
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        cell?.accessoryView = activityIndicator

        let dataTask = urlSession.dataTask(with: requestModel.url) { (data, response, error) in
            DispatchQueue.main.sync {
                if let httpUrlResponse = response as? HTTPURLResponse {
                    let label = UILabel()
                    label.text = "\(httpUrlResponse.statusCode)"
                    label.sizeToFit()
                    cell?.accessoryView = label
                    if let data = data {
                        cell?.detailTextLabel?.text = String(bytes: data, encoding: .utf8)
                    }
                } else {
                    cell?.accessoryView = nil
                }
            }
        }
        dataTask.resume()
    }
    
}

extension RequestsTableViewController: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic) {
            let credential = URLCredential(user: "guest", password: "guest", persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
