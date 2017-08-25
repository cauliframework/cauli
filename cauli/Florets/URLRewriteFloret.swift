//
//  URLRewriteFloret.swift
//  cauli
//
//  Created by Pascal Stüdlein on 14.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

/// This Floret checks the URLRequest for matching a specfic substring. On a match, the substring is replaced by a predefined value.
public class URLRewriteFloret: Floret {
    
    let replacementString: String
    let searchString: String
    
    public init(replaceMe: String, withThis: String) {
        self.replacementString = replaceMe
        self.searchString = withThis
    }
    
    public func request(for request: URLRequest) -> URLRequest? {
        guard let url = request.url,
            url.absoluteString.contains(self.replacementString),
            let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return nil }
        
        let newUrlString = url.absoluteString.replacingOccurrences(of: self.replacementString, with: self.searchString)
        mutableRequest.url = URL(string: newUrlString)
        
        return mutableRequest as URLRequest
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
}
