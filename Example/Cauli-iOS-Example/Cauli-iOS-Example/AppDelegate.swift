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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        cauli = Cauli(storage: MemoryStorage())
        cauli.florets = newFlorets()
        cauli.adapter.enable()

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
