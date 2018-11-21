//
//  WebViewController.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 17.11.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: "https://cauli.works")!))
    }
}
