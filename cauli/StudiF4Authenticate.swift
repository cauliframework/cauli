//
//  StudiF4Authenticate.swift
//  cauli
//
//  Created by Pascal Stüdlein on 09.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class StudiF4Authenticate: Floret {
    func canHandle(_ request: URLRequest) -> Bool {
        return request.url?.absoluteString.contains("studi.f4.htw-berlin.de/~s0549433/") ?? false
    }

    func request(for request: URLRequest) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return request }
        
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
    
    func response(for response: URLResponse) -> URLResponse {
        return response
    }
}
