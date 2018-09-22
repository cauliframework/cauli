//
//  MockResponseSerializer.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 22.09.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal class MockResponseSerializer {

    private enum Stored {
        case response(HTTPURLResponse, Data?)
        case data(Data)
        case both(Data, HTTPURLResponse, Data?)
    }

    private var stored: Stored

    init?(_ response: Response) {
        guard let urlResponse = response.urlResponse as? HTTPURLResponse else { return nil }
        stored = .response(urlResponse, response.data)
    }

    init?(_ data: Data) {
        stored = .data(data)
    }

    static let headersBlacklist: [AnyHashable] = []

    func data() -> Data {
        switch stored {
        case let .response(urlResponse, data):
            let headerStrings = urlResponse.allHeaderFields.compactMap { key, value -> String? in
                guard !MockResponseSerializer.headersBlacklist.contains(key) else { return nil }
                return "\(key): \(value)"
            }
            let firstLineHeader = "HTTP/1.1 \(urlResponse.statusCode) UNIMPORTANT"
            let headerString = ([firstLineHeader] + headerStrings + ["", ""]).joined(separator: "\n")
            let headerData = headerString.data(using: .utf8)!
            if let data = data {
                stored = .both(headerData + data, urlResponse, data)
                return headerData + data
            } else {
                stored = .both(headerData, urlResponse, data)
                return headerData
            }
        case let .data(data): return data
        case let .both(data, _, _): return data
        }
    }

    func response() -> (HTTPURLResponse, Data?) {
        fatalError("implement me")
    }

    func filename() -> String {
        return data().md5.description
    }

}
