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

/// Creates a short, single paragraph preview of a request or response body for the record details.
///
/// JSON is shown compacted, without the whitespace between its tokens, so the preview shows as much
/// of the content as possible while keeping the original order of the keys. Other text has its
/// whitespace and line breaks collapsed. Binary data has no preview.
internal enum BodyPreview {

    /// Only the beginning of a body is looked at, so large bodies don't slow down the record details.
    static let inspectedByteCount = 4 * 1024

    /// The maximum length of a preview, before it is truncated with "…".
    static let maximumLength = 500

    static func preview(of data: Data?) -> String? {
        guard let data = data, !data.isEmpty, let text = utf8Prefix(of: data) else { return nil }

        let isTruncated = data.count > inspectedByteCount
        var preview = isJSON(text) ? compactedJSON(text) : collapsedWhitespace(text)
        guard !preview.isEmpty else { return nil }

        if preview.count > maximumLength {
            preview = String(preview.prefix(maximumLength))
            return preview + "…"
        }
        return isTruncated ? preview + "…" : preview
    }

    /// The beginning of the data as UTF-8 text, or `nil` if it isn't text.
    private static func utf8Prefix(of data: Data) -> String? {
        let prefix = data.prefix(inspectedByteCount)
        // The prefix may end in the middle of a multi-byte character, so drop up to three trailing bytes.
        for droppedBytes in 0...min(3, prefix.count - 1) {
            if let text = String(data: prefix.dropLast(droppedBytes), encoding: .utf8) {
                return text.contains("\0") ? nil : text
            }
            if data.count <= inspectedByteCount {
                // The data wasn't cut, so it isn't valid UTF-8 text.
                return nil
            }
        }
        return nil
    }

    private static func isJSON(_ text: String) -> Bool {
        guard let first = text.first(where: { !$0.isWhitespace }) else { return false }
        return first == "{" || first == "["
    }

    /// Removes all whitespace outside of strings.
    private static func compactedJSON(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var isInString = false
        var isEscaped = false
        for character in text {
            if isInString {
                result.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }
            } else if character == "\"" {
                isInString = true
                result.append(character)
            } else if !character.isWhitespace {
                result.append(character)
            }
        }
        return result
    }

    /// Replaces every run of whitespace, including line breaks, by a single space.
    private static func collapsedWhitespace(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
}
