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

public struct Response: Codable {
    public var data: Data?
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

    public var suggestedFilename: String {
        // TODO: Check the Content-Disposition header for a possible filename
        let uuid = UUID().uuidString
        if let mimetypeString = urlResponse.mimeType,
            let mimeType = MimeType(rawValue: mimetypeString) {
            return uuid.appending(".\(mimeType.fileExtension)")
        } else {
            return uuid
        }
    }
}

enum MimeType: String {
    case json = "application/json"
    case xml = "application/xml"
    case html = "text/html"
    case text = "text/plain"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .xml: return "xml"
        case .html: return "html"
        case .text: return "txt"
        }
    }
}
