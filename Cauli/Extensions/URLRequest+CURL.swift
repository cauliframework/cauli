//
//  Copyright (c) 2021 cauli.works
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

extension URLRequest {

    var cURL: String {
        guard let url = url,
              let httpMethod = httpMethod else {
            assertionFailure("")
            return ""
        }

        var options: [String] = ["-X \(httpMethod)"]

        if let httpHeaderFields = allHTTPHeaderFields,
           !httpHeaderFields.isEmpty {
            let combinedHeaders = httpHeaderFields.reduce("") { result, httpHeaderField -> String in
                var mutableResult = result
                mutableResult += "-H \"\(httpHeaderField.key): \(httpHeaderField.value)\""
                return mutableResult
            }
            options.append(combinedHeaders)
        }

        if let httpBody = httpBody,
           let httpBodyString = String(data: httpBody, encoding: .utf8),
           !httpBodyString.isEmpty {
            options.append("-d \"\(httpBodyString)\"")
        }

        let commandParts = ["curl",
                            options.joined(separator: " "),
                            url.absoluteString]
        return commandParts.compactMap {
            guard !$0.isEmpty else { return nil }
            return $0
        }
        .joined(separator: " ")
    }

}
