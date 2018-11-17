//
//  FindReplaceFloret.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 21.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation
import Cauli

struct ReplaceDefinition<Type> {
    let keyPath: WritableKeyPath<Record, Type>
    let replacer: (Type) -> (Type)
}

extension ReplaceDefinition {
    static func modifyUrl(expression: NSRegularExpression, replacement: String) -> ReplaceDefinition<URLRequest> {
        let keyPath = \Record.designatedRequest
        let replacer: (URLRequest) -> (URLRequest) = { request in
            guard let oldURL = request.url else { return request }
            var newRequest = request
            newRequest.url = URL(string: oldURL.absoluteString.replacingOcurrences(of: expression, with: replacement))
            return request
        }
        return ReplaceDefinition<URLRequest>(keyPath: keyPath, replacer: replacer)
    }
}

final class FindReplaceFloret: Floret {
    var enabled: Bool = true
    
    let replacements: [ReplaceDefinition<Any>]
    
    init(replacements: [ReplaceDefinition<Any>]) {
        self.replacements = replacements
    }
    
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        let record = replacements.reduce(record, { (record, replacement) -> Record in
            var newRecord = record
            let oldValue = record[keyPath: replacement.keyPath]
            let modifiedValue = replacement.replacer(oldValue)
            newRecord[keyPath: replacement.keyPath] = modifiedValue
            return newRecord
        })
        try? completionHandler(record)
    }
    
    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) throws -> Void) {
        let record = replacements.reduce(record, { (record, replacement) -> Record in
            var newRecord = record
            let oldValue = record[keyPath: replacement.keyPath]
            let modifiedValue = replacement.replacer(oldValue)
            newRecord[keyPath: replacement.keyPath] = modifiedValue
            return newRecord
        })
        try? completionHandler(record)
    }
}
