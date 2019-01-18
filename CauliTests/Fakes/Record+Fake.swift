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
@testable import Cauli

extension Record {
    static func fake() -> Record {
        return fake(with: URL(string: "spec_fake_url")!)
    }
    static func fake(with url: URL) -> Record {
        return Record(URLRequest(url: url))
    }
    func setting(identifier: UUID) -> Record {
        return Record(identifier: identifier, originalRequest: originalRequest, designatedRequest: designatedRequest, result: result, requestStarted: nil, responseRecieved: nil)
    }
    func setting(originalRequestUrl url: URL) -> Record {
        return Record(identifier: identifier, originalRequest: URLRequest(url: url), designatedRequest: designatedRequest, result: result, requestStarted: requestStarted, responseRecieved: responseRecieved)
    }
    mutating func setting(designatedRequestsHeaderFields headerFields: [String: String]?) {
        designatedRequest.allHTTPHeaderFields?.keys.forEach {
            designatedRequest.setValue(nil, forHTTPHeaderField: $0)
        }
        
        headerFields?.forEach {
            designatedRequest.setValue($1, forHTTPHeaderField: $0)
        }
    }
    mutating func setting(designatedRequestsCachePolicy cachePolicy: [String: String]?) {
        designatedRequest.cachePolicy = .reloadIgnoringLocalCacheData
    }
    mutating func setting(httpURLResponse response: HTTPURLResponse) {
        result = .result(Response(response, data: nil))
    }
}
