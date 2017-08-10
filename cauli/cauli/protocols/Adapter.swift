//
//  Adapter.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// An Adapter intercepts the NetworkTraffic.
/// It passes the data to an Cauli instance.
public protocol Adapter {
    
    /// On initialization an Adapter should store a reference to a cauli instance.
    ///
    /// - Parameter cauli: reference to store for passing network traffic later on
    init(cauli: Cauli)
}
