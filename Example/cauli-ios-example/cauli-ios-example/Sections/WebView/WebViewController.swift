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
    private let webView: WKWebView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.frame = view.bounds
        
        webView.load(URLRequest(url: URL(string: "https://cauli.works")!))
    }
}
