//
//  URLSessionConfigurationExtension.swift
//  cauli
//
//  Created by Pascal Stüdlein on 09.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
    class func cauliDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = cauliDefaultSessionConfiguration()
        URLProtocolAdapter.register(for: configuration)
        return configuration
    }
    
//    override open class func initialize() {
//        super.initialize()
//        URLProtocolAdapter.swizzle()
//    }
}
