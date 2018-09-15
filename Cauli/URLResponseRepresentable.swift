//
//  URLResponseRepresentable.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 26.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

internal enum URLResponseRepresentable {
    case urlResponse(URLResponse)
    case httpURLResponse(HTTPURLResponse)

    internal var urlResponse: URLResponse {
        switch self {
        case .urlResponse(let urlResponse): return urlResponse
        case .httpURLResponse(let httpURLResponse): return httpURLResponse as URLResponse
        }
    }

    init(_ urlResponse: URLResponse) {
        if let urlResponse = urlResponse as? HTTPURLResponse {
            self = .httpURLResponse(urlResponse)
        } else {
            self = .urlResponse(urlResponse)
        }
    }
}

extension URLResponseRepresentable: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedData = try container.decode(Data.self)
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: decodedData)

        guard let httpURLResponse = unarchiver.decodeObject(of: [HTTPURLResponse.self, URLResponse.self], forKey: "URLResponseRepresentable") as? URLResponse else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "🤷‍♂️") }
        unarchiver.finishDecoding()

        self.init(httpURLResponse)
    }

    func encode(to encoder: Encoder) throws {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(urlResponse, forKey: "URLResponseRepresentable")
        archiver.finishEncoding()

        var container = encoder.singleValueContainer()
        try container.encode(archiver.encodedData)
    }
}
