//
//  AnonymizeIPFloret.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 07.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation
import Cauli

final class AnonymizeIPFloret: Floret {
    
    var enabled: Bool = true
    
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        completionHandler(record)
    }
    
    
    // Don't really use these expressions. They are just here for demonstrating purposes.
    static let ipV4Expression = try! NSRegularExpression(pattern: "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)", options: [])
    static let ipV6Expression = try! NSRegularExpression(pattern: "([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4})", options: [])

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        guard case let .result(response)? = record.result,
            let data = response.data,
            let dataString = String(bytes: data, encoding: .utf8) else { completionHandler(record); return }
        let anonymizedString = dataString.replacingOcurrences(of: AnonymizeIPFloret.ipV4Expression, with: "$1.$2.$3.000").replacingOcurrences(of: AnonymizeIPFloret.ipV6Expression, with: "$1:$2:$3:$4:0:0:0:0")
        let anonymizedData = anonymizedString.data(using: .utf8)
        var anonymizedResponse = response
        anonymizedResponse.data = anonymizedData
        var anonymizedRecord = record
        anonymizedRecord.result = .result(anonymizedResponse)
        completionHandler(anonymizedRecord)
    }
}
