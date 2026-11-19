//
//  Copyright (c) 2026 cauli.works
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

    /// A cURL command performing this request, e.g. to reproduce it in a terminal.
    ///
    /// All values are quoted for POSIX shells, so the command can be pasted as is.
    /// A body that isn't UTF-8 text, or a body stream, can't be included and is
    /// mentioned in a comment at the end of the command instead.
    internal var cURLCommand: String {
        var arguments = ["curl", "-X \((httpMethod ?? "GET").shellQuoted)"]

        let headerFields = (allHTTPHeaderFields ?? [:]).sorted { $0.key < $1.key }
        arguments += headerFields.map { "-H \("\($0.key): \($0.value)".shellQuoted)" }

        var comment: String?
        if let httpBody = httpBody, !httpBody.isEmpty {
            if let bodyString = String(data: httpBody, encoding: .utf8), !bodyString.contains("\0") {
                arguments.append("--data-binary \(bodyString.shellQuoted)")
            } else {
                comment = "# The binary body of \(httpBody.count) bytes is not included."
            }
        } else if httpBodyStream != nil {
            comment = "# The body stream is not included."
        }

        arguments.append((url?.absoluteString ?? "").shellQuoted)

        let command = arguments.joined(separator: " \\\n  ")
        return comment.map { "\(command)\n\($0)" } ?? command
    }
}

private extension String {
    static let shellSafeCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./:=@%+,")

    /// The string as single shell argument. It is only quoted if necessary.
    var shellQuoted: String {
        if !isEmpty && unicodeScalars.allSatisfy({ String.shellSafeCharacters.contains($0) }) {
            return self
        }
        // Inside single quotes nothing is interpreted, a single quote is written as '\''.
        return "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
