//
//  Cauli+Customized.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 04.10.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation
import Cauliframework

internal extension Cauli {
    static let findReplaceFloret: FindReplaceFloret = {
        let expresssion = try! NSRegularExpression(pattern: "^http://", options: [])
        let httpsUrl = RecordModifier.modifyUrl(expression: expresssion, template: "https://")
        return FindReplaceFloret(willRequestModifiers: [httpsUrl], name: "https-ify Floret")
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
    static let customShared = Cauli([HTTPBodyStreamFloret(), findReplaceFloret, mockFloret, inspectorFloret], configuration: Configuration.standard)
}
