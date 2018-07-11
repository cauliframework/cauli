//
//  Weak.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}
