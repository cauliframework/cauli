//
//  StudiF3Rewrite.swift
//  cauli
//
//  Created by Pascal Stüdlein on 10.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class StudiF3Rewrite: Floret {
    func request(for request: URLRequest) -> URLRequest? {
        guard let url = request.url,
            url.absoluteString.contains("studi.f3.htw-berlin.de"),
            let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return nil }
        
        let newUrlString = url.absoluteString.replacingOccurrences(of: "studi.f3.htw-berlin.de", with: "studi.f4.htw-berlin.de")
        mutableRequest.url = URL(string: newUrlString)
        
        return mutableRequest as URLRequest
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
    
    func error(for request: URLRequest) -> Error? {
        return nil
    }
}
