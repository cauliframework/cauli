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

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Cauli.customShared.run()
        Cauli.mockFloret.mode = .mock
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
}
