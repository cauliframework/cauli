//
//  BlackHoleFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class BlackHoleFloret: Floret {
    func request(for request: URLRequest) -> URLRequest? {
        return request
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
}
