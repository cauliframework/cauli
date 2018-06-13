//
//  SwizzledURLProtocolAdapter.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

public class SwizzledURLProtocolAdapter: SingleSessionURLProtocolAdapter {
    
    required public init() {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.protocolClasses = sessionConfiguration.protocolClasses?.filter({ $0 != CauliURLProtocol.self })
        super.init(sessionConfiguration: sessionConfiguration)
    }
    
    required public init(sessionConfiguration: URLSessionConfiguration?) {
        super.init(sessionConfiguration: sessionConfiguration)
    }
    
    public override func enable() {
        if !isEnabled {
            URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        }
        super.enable()
    }
    
    public override func disable() {
        if isEnabled {
            URLSessionConfiguration.cauliSwizzleDefaultSessionConfigurationGetter()
        }
        super.disable()
    }
}


// This extension performes all the swizzling logic
// to replace the `URLSessionConfiguration.default` with one, where
// the `protocolClasses` contain the `CauliURLProtocol`
extension URLSessionConfiguration {
    internal static let cauliDefaultSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
    internal static let cauliSwizzledSessionConfigurationGetterMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.cauliDefaultSessionConfiguration))
    
    internal class func cauliDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = cauliDefaultSessionConfiguration() // since it is swizzled, this will call the original implementation
        let protocolClasses = configuration.protocolClasses ?? []
        configuration.protocolClasses = [CauliURLProtocol.self] + protocolClasses
        return configuration
    }
    
    internal class func cauliSwizzleDefaultSessionConfigurationGetter() {
        method_exchangeImplementations(cauliDefaultSessionConfigurationGetterMethod, cauliSwizzledSessionConfigurationGetterMethod)
    }
}
