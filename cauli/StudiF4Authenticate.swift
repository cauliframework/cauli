//
//  StudiF4Authenticate.swift
//  cauli
//
//  Created by Pascal Stüdlein on 09.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class StudiF4Authenticate: Floret {
    func request(for request: URLRequest?) -> URLRequest? {
        guard let req = request,
            req.url?.absoluteString.contains("studi.f4.htw-berlin.de/~s0549433/") ?? false,
            let mutableRequest = (req as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return request }
        
        let userPasswordString = "secure:secure123"
        let userPasswordData = userPasswordString.data(using: .utf8)
        let base64EncodedCredential = userPasswordData?.base64EncodedString() ?? ""
        let authString = "Basic \(base64EncodedCredential)"
        mutableRequest.allHTTPHeaderFields?["Authorization"] = authString
        return mutableRequest as URLRequest
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
}
