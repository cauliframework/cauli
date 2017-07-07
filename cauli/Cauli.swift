//
//  Cauli.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class Cauli {
    
    var florets: [Floret] = []
    let adapter: Adapter
    let storage: Storage

    init(adapter: Adapter, storage: Storage) {
        self.adapter = adapter
        self.storage = storage
    }
    
}
