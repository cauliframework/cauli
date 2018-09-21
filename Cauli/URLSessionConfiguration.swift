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

// This extension performes all the swizzling logic
// to replace the `URLSessionConfiguration.default` with one, where
// the `protocolClasses` contain the `CauliURLProtocol`
extension URLSessionConfiguration {
    // swiftlint:disable force_unwrapping identifier_name
    internal static let cauliDefaultSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))!
    internal static let cauliSwizzledSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.cauliDefaultSessionConfiguration))!
    // swiftlint:enable force_unwrapping identifier_name

    @objc internal class func cauliDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = cauliDefaultSessionConfiguration() // since it is swizzled, this will call the original implementation
        let protocolClasses = configuration.protocolClasses ?? []
        configuration.protocolClasses = [CauliURLProtocol.self] + protocolClasses
        return configuration
    }

    @objc internal class func cauliSwizzleDefaultSessionConfigurationGetter() {
        method_exchangeImplementations(cauliDefaultSessionConfigurationGetterMethod, cauliSwizzledSessionConfigurationGetterMethod)
    }
}
