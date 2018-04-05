//
//  FailRequestFloret.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 22.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import Foundation
import Cauli

extension String: Error {
    public var localizedDescription: String {
        return self
    }
}

class FailRequestFloret: Floret {
    let urlToFail: String
    
    init(urlToFail: String) {
        self.urlToFail = urlToFail
    }
    
    func request(for request: URLRequest) -> URLRequest? {
        guard let url = request.url, url.absoluteString == self.urlToFail else { return nil }
        return request
    }
    
    func error(for request: URLRequest) -> Error? {
        guard let url = request.url, url.absoluteString == self.urlToFail else { return nil }
        return "Cauli Error"
    }
}
