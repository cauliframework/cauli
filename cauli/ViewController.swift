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
    
    var cauli: Cauli = {
        let adapter = URLProtocolAdapter()
        
        let cauli = Cauli(adapter: adapter)
        cauli.florets = [BlackHoleFloret(), StudiF4Authenticate()]
        return cauli
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: URL(string: "https://studi.f4.htw-berlin.de/~s0549433/")!)
        let first = Date()
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print("\(response)")
                let second = Date()
                print(second.timeIntervalSince1970 - first.timeIntervalSince1970)
            }
        }.resume()
    }
}
