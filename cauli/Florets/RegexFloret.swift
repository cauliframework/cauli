//
//  RegexFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 14.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// This Floret is typically used as first floret of a cauli instance and acts as filter. 
/// It checks if the request url is matching the predefined regular expression.
/// On a match it announce to handle this specific request. 
/// It won't modify the request itself, the data or the response.
public class RegexFloret: Floret {
    
    let regex: NSRegularExpression
    
    public init(regex: NSRegularExpression) {
        self.regex = regex
    }
    
    public func request(for request: URLRequest) -> URLRequest? {
        if let absoluteUrlString = request.url?.absoluteString,
            self.regex.matches(in: absoluteUrlString, range: NSMakeRange(0, absoluteUrlString.utf16.count)).count > 0 {
            return request
        }
        
        return nil
    }
    
    public func response(for request: URLRequest) -> URLResponse? {
        return nil
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
    
    public func error(for error: Error, request: URLRequest) -> Error {
        return error
    }
}
