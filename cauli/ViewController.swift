//
//  ViewController.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var session: URLSession! = {
        let sessionConfiguration = URLSessionConfiguration.default
        URLProtocolAdapter.register(for: sessionConfiguration)
        return URLSession(configuration: sessionConfiguration)
    }()
    
    var storage: Storage!
    
//    var cauli: Cauli!
    var urlProtocolAdapter: URLProtocolAdapter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        storage = PrintStorage()
        
        let cauli = Cauli(storage: storage)
        let regex = try! NSRegularExpression(pattern: ".*htw.*", options: [])
        
        cauli.florets = [
            BlackHoleFloret(), RegexFloret(regex: regex), URLRewriteFloret(replaceMe: "studi.f3.htw-berlin.de", withThis: "google.de")
        ]
        
        urlProtocolAdapter = URLProtocolAdapter(cauli: cauli)
        
        let request = URLRequest(url: URL(string: "https://studi.f3.htw-berlin.de/")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        session.dataTask(with: request) { (data, response, error) in
            print(self.storage.records)
        }.resume()
    }
}
