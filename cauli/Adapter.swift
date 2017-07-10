//
//  Adapter.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

protocol Adapter {
    weak var cauli: Cauli? { get set }
    
    func configure()
}
