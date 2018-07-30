//
//  FloretProtocol.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 29.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public protocol Floret {
    func willRequest(_ record: Record) -> Record
    func didRespond(_ record: Record) -> Record
}
