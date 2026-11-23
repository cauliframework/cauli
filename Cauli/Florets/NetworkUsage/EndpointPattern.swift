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

/// Replaces ids in url paths, so requests to the same endpoint are counted together.
internal enum EndpointPattern {

    /// "/users/42/posts/9f8e…" becomes "/users/:id/posts/:id". Numbers, UUIDs and long
    /// hexadecimal strings count as ids.
    static func pattern(for path: String) -> String {
        guard !path.isEmpty else { return "/" }
        return path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { isID($0) ? ":id" : String($0) }
            .joined(separator: "/")
    }

    private static func isID(_ segment: Substring) -> Bool {
        guard !segment.isEmpty else { return false }
        if segment.allSatisfy(\.isNumber) { return true }
        if UUID(uuidString: String(segment)) != nil { return true }
        return segment.count >= 16 && segment.allSatisfy(\.isHexDigit)
    }
}
