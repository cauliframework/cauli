//
//  Response.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 15.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

public struct Response: Codable {
    public let data: Data?
    public var urlResponse: URLResponse {
        get {
            return urlResponseRepresentable.urlResponse
        }
        set {
            urlResponseRepresentable = URLResponseRepresentable(newValue)
        }
    }

    init(_ urlResponse: URLResponse, data: Data?) {
        self.data = data
        urlResponseRepresentable = URLResponseRepresentable(urlResponse)
    }

    private var urlResponseRepresentable: URLResponseRepresentable
}
