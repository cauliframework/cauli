//
//  ComDomainFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation
import cauli

class ComDomainFloret: Floret {
    func request(for request: URLRequest) -> URLRequest? {
        guard let url = request.url, url.absoluteString.contains(".com") else { return nil }
        return request
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
}
