//
//  Cauli+Customized.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 04.10.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation
import Cauli

internal extension Cauli {
    static let anonymizeIPFloret = AnonymizeIPFloret()
    static let findReplaceFloret: FindReplaceFloret = {
//        let sslUrl = ReplaceDefinition<Any>.modifyUrl(expression: try! NSRegularExpression(pattern: "http[^s]", options: []), replacement: "$1s") as! ReplaceDefinition<Any>
//        return FindReplaceFloret(replacements: [sslUrl])
        return FindReplaceFloret(replacements: [])
    }()
    static let mockFloret: MockFloret = {
        let floret = MockFloret()
        floret.addMapping() { request, floret in
            guard let host = request.url?.host,
                host == "invalidurl.invalid" else { return nil }
            return floret.resultForPath("2e018ce0e517c39e2717efb0151e3b65/97f6f69543dd9e669ee47a0cabbb40b8")
        }
        floret.addMapping(forUrlPath: "/404") { request, floret in
            return floret.resultForPath("default/404")
        }
        return floret
    }()
    static let inspectorFloret = InspectorFloret()
    static let customShared = Cauli([anonymizeIPFloret, findReplaceFloret, mockFloret, inspectorFloret], configuration: Configuration.standard)
}
