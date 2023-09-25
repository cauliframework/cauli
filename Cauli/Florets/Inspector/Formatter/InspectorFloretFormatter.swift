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

internal class InspectorFloretFormatter: InspectorFloretFormatterType {

    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        return timeFormatter
    }()

    func listFormattedData(for record: Record) -> InspectorFloret.RecordListFormattedData {
        let method = record.designatedRequest.httpMethod ?? ""
        let path = record.designatedRequest.url?.absoluteString ?? ""
        let time: String
        if let requestStarted = record.requestStarted {
            time = Self.timeFormatter.string(from: requestStarted)
        } else {
            time = ""
        }
        let status: String
        let statusColor: UIColor
        switch record.result {
        case nil:
            status = "-"
            statusColor = Self.grayColor
        case .error(let error)?:
            status = error.cauli_networkErrorShortString
            statusColor = Self.redColor
        case .result(let response)?:
            if let httpUrlResponse = response.urlResponse as? HTTPURLResponse {
                status = "\(httpUrlResponse.statusCode)"
                statusColor = colorForHTTPStatusCode(httpUrlResponse.statusCode)
            } else {
                status = "-"
                statusColor = Self.grayColor
            }
        }
        return InspectorFloret.RecordListFormattedData(method: method, path: path, time: time, status: status, statusColor: statusColor)
    }

    static let greenColor = UIColor(red: 11 / 255.0, green: 176 / 255.0, blue: 61 / 255.0, alpha: 1)
    static let blueColor = UIColor(red: 74 / 255.0, green: 144 / 255.0, blue: 226 / 255.0, alpha: 1)
    static let redColor = UIColor(red: 210 / 255.0, green: 46 / 255.0, blue: 14 / 255.0, alpha: 1)
    static let grayColor = UIColor(red: 155 / 255.0, green: 155 / 255.0, blue: 155 / 255.0, alpha: 1)
    private func colorForHTTPStatusCode(_ statusCode: Int) -> UIColor {
        switch statusCode {
        case 0..<300: return Self.greenColor
        case 300..<400: return Self.blueColor
        case 400..<600: return Self.redColor
        default: return Self.grayColor
        }
    }
    
}
