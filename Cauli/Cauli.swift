//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
    
    deinit {
        CauliURLProtocol.remove(delegate: self)
    }
    
    init() {
        CauliURLProtocol.add(delegate: self)
    }
    
}

// For now we don't add any custom implementation here
extension Cauli: CauliURLProtocolDelegate {
    func canHandle(_ request: URLRequest) -> Bool {
        // TODO: implement me
        return false
    }
    
    func willRequest(_ record: Record) -> Record {
        // TODO: implement me
        return record
    }
    
    func didRespond(_ record: Record) -> Record {
        // TODO: implement me
        return record
    }
}
