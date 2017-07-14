//
//  BlackHoleFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public class BlackHoleFloret: Floret {
    public init() {}
    
    public func request(for request: URLRequest) -> URLRequest? {
        return request
    }
    
    public func response(for request: URLRequest) -> URLResponse? {
        return nil//URLResponse(url: URL(string: "https://partyparty.de")!, mimeType: nil, expectedContentLength: 1234, textEncodingName: nil)
    }
    
    public func response(for response: URLResponse) -> URLResponse? {
        return response
    }
    
    public func data(for data: Data?, request: URLRequest) -> Data? {
        return data
    }
    
    public func error(for request: URLRequest) -> Error? {
        return nil
    }
}
