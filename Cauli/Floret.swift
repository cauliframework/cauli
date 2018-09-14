//
//  FloretProtocol.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 29.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public protocol Floret {
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void)
    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void)
}
