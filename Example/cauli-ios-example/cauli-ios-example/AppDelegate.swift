//
//  AppDelegate.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 06.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import UIKit
import Cauli

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Cauli.customShared.run()
        Cauli.mockFloret.mode = .record
        Cauli.mockFloret.enabled = false
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
}
