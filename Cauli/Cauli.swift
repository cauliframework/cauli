//
//  Cauli.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 11.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public class Cauli{
    
    init() {
        // swizzle the URLSessionConfiguration.default getter and add the CauliURLProtocol to it
        // make sure the CauliURLProtocol passes every call to Cauli
    }
    
}

// CauliURLProtocolDelegate
extension Cauli {
    func canInit(with request: URLRequest) -> Bool {
        // TODO: implement me
        return false
    }
    
}
