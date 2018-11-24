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

import UIKit

class InspectorRecordTableViewCell: UITableViewCell {

    static let reuseIdentifier = "InsectorRecordTableViewCell"

    @IBOutlet weak var methodLabel: TagLabel!
    @IBOutlet weak var pathLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTypeLabel: UILabel!
    @IBOutlet weak var statusCodeLabel: TagLabel!

    public var record: Record? {
        didSet {
            if let record = record {
                load(from: record)
            }
        }
    }

    private func load(from record: Record) {
        methodLabel.text = record.designatedRequest.httpMethod
        pathLabel.text = record.designatedRequest.url?.absoluteString
        switch record.result {
        case .none:
            break
        case .error(let error):
            break
        case .result(let response):
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                contentTypeLabel.text = httpUrlResponse.allHeaderFields["Content-Type"] as? String
                statusCodeLabel.text = "\(httpUrlResponse.statusCode)"
                statusCodeLabel.borderColor = colorForHTTPStatusCode(httpUrlResponse.statusCode)
            }
        }
    }

    // green: UIColor(displayP3Red: 126/255.0, green: 211/255.0, blue: 33/255.0, alpha: 1)
    // blue: UIColor(displayP3Red: 74/255.0, green: 144/255.0, blue: 226/255.0, alpha: 1)
    // red: UIColor(displayP3Red: 208/255.0, green: 2/255.0, blue: 27/255.0, alpha: 1)
    private func colorForHTTPStatusCode(_ statusCode: Int) -> UIColor {
        switch statusCode {
        case 0..<300: return UIColor(displayP3Red: 126 / 255.0, green: 211 / 255.0, blue: 33 / 255.0, alpha: 1)
        case 300..<400: return UIColor(displayP3Red: 74 / 255.0, green: 144 / 255.0, blue: 226 / 255.0, alpha: 1)
        case 400..<600: return UIColor(displayP3Red: 208 / 255.0, green: 2 / 255.0, blue: 27 / 255.0, alpha: 1)
        default: return UIColor.black
        }
    }

}
