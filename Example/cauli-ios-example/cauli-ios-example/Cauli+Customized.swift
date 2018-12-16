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
        let expresssion = try! NSRegularExpression(pattern: "^http://", options: [])
        let httpsUrl = ReplaceDefinition.modifyUrl(expression: expresssion, replacement: "https://")
        return FindReplaceFloret(replacements: [httpsUrl])
    }()
    static let mockFloret = MockFloret()
    static let inspectorFloret = InspectorFloret()
    static let customShared = Cauli([anonymizeIPFloret, findReplaceFloret, mockFloret, inspectorFloret], configuration: Configuration.standard)
}
