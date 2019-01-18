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

internal struct SwappedResponse: Codable {
    let dataFilename: String?
    var urlResponse: URLResponse {
        get {
            return urlResponseRepresentable.urlResponse
        }
        set {
            urlResponseRepresentable = URLResponseRepresentable(newValue)
        }
    }

    init(_ urlResponse: URLResponse, dataFilename: String?) {
        self.dataFilename = dataFilename
        urlResponseRepresentable = URLResponseRepresentable(urlResponse)
    }

    var urlResponseRepresentable: URLResponseRepresentable
}

extension SwappedResponse {
    init(_ response: Response, dataFilepath: URL) {
        self.urlResponseRepresentable = URLResponseRepresentable(response.urlResponse)

        if let data = response.data,
            (try? data.write(to: dataFilepath)) != nil {
            self.dataFilename = dataFilepath.lastPathComponent
        } else {
            self.dataFilename = nil
        }
    }

    func response(in folder: URL) -> Response {
        var response = Response(urlResponse, data: nil)
        response.data = nil

        if let dataFilename = dataFilename,
            let data = try? Data(contentsOf: folder.appendingPathComponent(dataFilename)) {
            response.data = data
        }

        return response
    }
}
