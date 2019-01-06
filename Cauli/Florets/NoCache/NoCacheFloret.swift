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

public class NoCacheFloret: FindReplaceFloret {

    required public init() {
        let willRequestReplaceDefinition = ReplaceDefinition(keyPath: \Record.designatedRequest) { designatedRequest -> (URLRequest) in
            var request = designatedRequest
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            request.allHTTPHeaderFields?.removeValue(forKey: "If-Modified-Since")
            request.allHTTPHeaderFields?.removeValue(forKey: "If-None-Match")
            request.allHTTPHeaderFields?["Cache-Control"] = "no-cache"

            return request
        }

        let didRespondReplaceDefinition = ReplaceDefinition(keyPath: \Record.result) { result -> Result<Response> in
            guard case .result(let response) = result, let httpURLResponse = response.urlResponse as? HTTPURLResponse, let url = httpURLResponse.url else { return result }
            
            var allHTTPHeaderFields = httpURLResponse.allHeaderFields as? [String: String] ?? [:]
            allHTTPHeaderFields.removeValue(forKey: "Last-Modified")
            allHTTPHeaderFields.removeValue(forKey: "ETag")
            allHTTPHeaderFields["Expires"] = "0"
            allHTTPHeaderFields["Cache-Control"] = "no-cache"

            guard let newHTTPURLRespones = HTTPURLResponse(url: url, statusCode: httpURLResponse.statusCode, httpVersion: nil, headerFields: allHTTPHeaderFields) else { return result }

            return Result.result(Response(newHTTPURLRespones, data: response.data))
        }
      
        super.init(willRequestReplacements: [willRequestReplaceDefinition], didRespondReplacements: [didRespondReplaceDefinition], name: "NoCacheFloret")
    }

}
