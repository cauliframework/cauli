//
//  PrintStorage.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

class PrintStorage: Storage {
    func store(_ request: URLRequest, originalRequest: URLRequest) {
        print("store request \(originalRequest)")
    }
    
    func store(_ response: URLResponse, for request: URLRequest) {
        print("store response for \(request)")
    }
}
