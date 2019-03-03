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

/// The NoCacheFloret modifies the desigantedRequest and the response of a record
/// to prevent returning cached data or writing data to the cache.
///
/// On the designatedRequest it will:
/// * change the **cachePolicy** to **.reloadIgnoringLocalCacheData**
/// * **remove** the value for the **If-Modified-Since** key on allHTTPHeaderFields
/// * **remove** the value for the **If-None-Match** key on allHTTPHeaderFields
/// * change **Cache-Control** to **no-cache**
///
/// On the response it will:
/// * **remove** the value for the **Last-Modified** key on allHTTPHeaderFields
/// * **remove** the value for the **ETag** key on allHTTPHeaderFields
/// * change **Expires** to **0**
/// * change **Cache-Control** to **no-cache**
public class NoCacheFloret: FindReplaceFloret {

    /// Public initalizer to create an instance of the `NoCacheFloret`.
    public required init() {
        let willRequestReplaceDefinition = RecordModifier(keyPath: \Record.designatedRequest) { designatedRequest -> (URLRequest) in
            var request = designatedRequest
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            request.setValue(nil, forHTTPHeaderField: "If-Modified-Since")
            request.setValue(nil, forHTTPHeaderField: "If-None-Match")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            return request
        }

        let didRespondReplaceDefinition = RecordModifier(keyPath: \Record.result) { result in
            guard case .result(let response)? = result, let httpURLResponse = response.urlResponse as? HTTPURLResponse, let url = httpURLResponse.url else { return result }

            var allHTTPHeaderFields = httpURLResponse.allHeaderFields as? [String: String] ?? [:]
            allHTTPHeaderFields.removeValue(forKey: "Last-Modified")
            allHTTPHeaderFields.removeValue(forKey: "ETag")
            allHTTPHeaderFields["Expires"] = "0"
            allHTTPHeaderFields["Cache-Control"] = "no-cache"

            guard let newHTTPURLRespones = HTTPURLResponse(url: url, statusCode: httpURLResponse.statusCode, httpVersion: nil, headerFields: allHTTPHeaderFields) else { return result }

            return Result.result(Response(newHTTPURLRespones, data: response.data))
        }

        super.init(willRequestModifiers: [willRequestReplaceDefinition], didRespondModifiers: [didRespondReplaceDefinition], name: "NoCacheFloret")
    }

}
