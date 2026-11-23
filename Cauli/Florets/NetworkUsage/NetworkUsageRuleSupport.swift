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

/// Helpers the built-in rules share.
internal enum NetworkUsageRuleSupport {

    /// The compression ratio assumed when the session has no compressed responses to learn from.
    /// Conservative for JSON and text, which typically compress 4 to 10 times.
    static let defaultCompressionRatio = 3.0

    /// The media types worth compressing: text, JSON, XML and JavaScript.
    static func isCompressible(_ mediaType: String?) -> Bool {
        guard let mediaType = mediaType else { return false }
        return mediaType.hasPrefix("text/")
            || mediaType.hasSuffix("json")
            || mediaType.hasSuffix("xml")
            || mediaType.hasSuffix("javascript")
    }

    /// The average ratio of decoded to received bytes of the compressed, compressible responses
    /// in the snapshot, e.g. 4.2. `defaultCompressionRatio` if there are none.
    static func compressionRatio(in usage: NetworkUsageSnapshot) -> Double {
        let compressed = usage.transfers.filter { transfer in
            transfer.isResponseCompressed && isCompressible(transfer.responseContentType) && transfer.metrics.responseBodyBytes > 0
        }
        let received = compressed.reduce(Int64(0)) { $0 + $1.metrics.responseBodyBytes }
        let decoded = compressed.reduce(Int64(0)) { $0 + $1.metrics.responseBodyBytesDecoded }
        guard received > 0, decoded > received else { return defaultCompressionRatio }
        return Double(decoded) / Double(received)
    }

    /// The bytes compressing `bytes` would save with the given ratio.
    static func saving(compressing bytes: Int64, ratio: Double) -> Int64 {
        Int64((Double(bytes) * (1 - 1 / ratio)).rounded())
    }

    /// E.g. "1.1 MB".
    static func format(bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    /// "1 endpoint" or "3 endpoints".
    static func count(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
}
