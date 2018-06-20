//
//  AppDelegate.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 20.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit
import Cauli

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var cauli: Cauli!
    var urlSession: URLSession!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let adapter = SingleSessionURLProtocolAdapter()
        cauli = Cauli(storage: MemoryStorage(), adapter: adapter)
        self.urlSession = adapter.urlSession;
        cauli.florets = newFlorets()
        cauli.enable()

        return true
    }
    
    func newFlorets() -> [Floret] {
        let regex = try! NSRegularExpression(pattern: ".*htw-berlin.*", options: [])
        
        let regexFloret = RegexFloret(regex: regex)
        let rewriteFloret = URLRewriteFloret(replaceMe: "www.f3.htw-berlin.de", withThis: "www.f4.htw-berlin.de")
        let fakeJsonFloret = FakeJSONFloret()
        let failRequestFloret = FailRequestFloret(urlToFail: "https://www.f2.htw-berlin.de")
        
        return [regexFloret, rewriteFloret, fakeJsonFloret, failRequestFloret]
    }
}
