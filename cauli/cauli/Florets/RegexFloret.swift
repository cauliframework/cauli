//
//  RegexFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 14.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class RegexFloret: Floret {
    
    let regex: NSRegularExpression
    
    init(regex: NSRegularExpression) {
        self.regex = regex
    }
    
    func request(for request: URLRequest) -> URLRequest? {
        if let absoluteUrlString = request.url?.absoluteString,
            self.regex.matches(in: absoluteUrlString, range: NSMakeRange(0, absoluteUrlString.utf16.count)).count > 0 {
            return request
        }
        
        return nil
    }
    
    func response(for request: URLRequest) -> URLResponse? {
        return nil
    }
    
    func response(for response: URLResponse) -> URLResponse? {
        return response
    }
    
    func data(for data: Data?, request: URLRequest) -> Data? {
        return data
    }
    
    func error(for request: URLRequest) -> Error? {
        return nil
    }
}
