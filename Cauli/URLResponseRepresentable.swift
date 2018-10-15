//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        let unarchivedObject: Any?

        if #available(iOS 11, *) {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: decodedData)
            unarchivedObject = unarchiver.decodeObject(of: [HTTPURLResponse.self, URLResponse.self], forKey: "URLResponseRepresentable")
            unarchiver.finishDecoding()
        } else {
            unarchivedObject = NSKeyedUnarchiver.unarchiveObject(with: decodedData)
        }

        guard let httpURLResponse = unarchivedObject as? URLResponse else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Could not unarchive decodedData as URLResponse") }

        self.init(httpURLResponse)
    }

    func encode(to encoder: Encoder) throws {
        let encodedData: Data

        if #available(iOS 11, *) {
            let archiver = NSKeyedArchiver(requiringSecureCoding: true)
            archiver.encode(urlResponse, forKey: "URLResponseRepresentable")
            archiver.finishEncoding()
            encodedData = archiver.encodedData
        } else {
            encodedData = NSKeyedArchiver.archivedData(withRootObject: urlResponse)
        }

        var container = encoder.singleValueContainer()
        try container.encode(encodedData)
    }
}
