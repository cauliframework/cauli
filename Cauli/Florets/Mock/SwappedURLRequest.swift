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

internal struct SwappedURLRequest: Codable {
    let url: URL
    let cachePolicy: URLRequest.CachePolicy
    let timeoutInterval: TimeInterval
    let mainDocumentURL: URL?
    let allowsCellularAccess: Bool
    let httpMethod: String?
    let allHTTPHeaderFields: [String: String]?
    let bodyFilename: String?
    let httpShouldHandleCookies: Bool
    let httpShouldUsePipelining: Bool
}

extension SwappedURLRequest {
    init(_ urlRequest: URLRequest, bodyFilepath: URL) {
        // swiftlint:disable force_unwrapping
        self.url = urlRequest.url ?? URL(string: "unknown")!
        // swiftlint:enable force_unwrapping
        self.cachePolicy = urlRequest.cachePolicy
        self.timeoutInterval = urlRequest.timeoutInterval
        self.mainDocumentURL = urlRequest.mainDocumentURL
        self.allowsCellularAccess = urlRequest.allowsCellularAccess
        self.httpMethod = urlRequest.httpMethod
        self.allHTTPHeaderFields = urlRequest.allHTTPHeaderFields
        self.httpShouldHandleCookies = urlRequest.httpShouldHandleCookies
        self.httpShouldUsePipelining = urlRequest.httpShouldUsePipelining

        if let body = urlRequest.httpBody,
            (try? body.write(to: bodyFilepath)) != nil {
            self.bodyFilename = bodyFilepath.lastPathComponent
        } else {
            self.bodyFilename = nil
        }
    }

    func urlRequest(in folder: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.mainDocumentURL = mainDocumentURL
        request.allowsCellularAccess = allowsCellularAccess
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = allHTTPHeaderFields
        request.httpShouldHandleCookies = httpShouldHandleCookies
        request.httpShouldUsePipelining = httpShouldUsePipelining

        if let bodyFilename = bodyFilename,
            let body = try? Data(contentsOf: folder.appendingPathComponent(bodyFilename)) {
            request.httpBody = body
        }

        return request
    }
}
