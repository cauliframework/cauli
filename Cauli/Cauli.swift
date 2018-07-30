//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli {
    
    public let florets: [Floret]
    
    deinit {
        CauliURLProtocol.remove(delegate: self)
    }
    
    init(florets: [Floret]) {
        self.florets = florets
        CauliURLProtocol.add(delegate: self)
    }
    
}

// For now we don't add any custom implementation here
extension Cauli: CauliURLProtocolDelegate {
    
    func willRequest(_ record: Record) -> Record {
        return florets.reduce(record) { (record, floret) -> Record in
            floret.willRequest(record)
        }
    }
    
    func didRespond(_ record: Record) -> Record {
        return florets.reduce(record) { (record, floret) -> Record in
            floret.didRespond(record)
        }
    }
    
}
