//
//  URLSessionConfiguration.swift
//  Cauli
//
//  Created by Cornelius Horstmann on 12.07.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

// This extension performes all the swizzling logic
// to replace the `URLSessionConfiguration.default` with one, where
// the `protocolClasses` contain the `CauliURLProtocol`
extension URLSessionConfiguration {
    internal static let cauliDefaultSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))!
    internal static let cauliSwizzledSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.cauliDefaultSessionConfiguration))!
    
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
