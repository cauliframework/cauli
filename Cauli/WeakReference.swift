//
//  WeakReference.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 08.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal class WeakReference<T> {
    weak var value: AnyObject?

    init(_ value: T?) {
        self.value = value as AnyObject
    }
}
