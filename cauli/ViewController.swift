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
    
    var cauli: Cauli!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let adapter = URLProtocolAdapter()
        storage = MemoryStorage()
        
        let cauli = Cauli(adapter: adapter, storage: storage)
        cauli.florets = [
            BlackHoleFloret(), StudiF3Rewrite(), StudiF4Authenticate()
        ]
        self.cauli = cauli
        
        
        let request = URLRequest(url: URL(string: "https://studi.f3.htw-berlin.de/~s0549433/")!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        session.dataTask(with: request) { (data, response, error) in
            print(self.storage.records)
        }.resume()
    }
}
