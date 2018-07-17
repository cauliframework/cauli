//
//  CauliURLProtocolDelegate.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

protocol CauliURLProtocolDelegate: AnyObject {
    func canHandle(_ request: URLRequest) -> Bool
    func willRequest(_ record: Record) -> Record
    func didRespond(_ record: Record) -> Record
}
