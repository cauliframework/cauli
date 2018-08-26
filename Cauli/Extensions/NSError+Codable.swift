//
//  NSError+Codable.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 26.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

struct InternalError: Codable {
    let domain: String
    let code: Int
    let userInfo: [String: String]
}

extension NSError {
    var compatibleUserInfo: [String: String] {
        return self.userInfo.reduce([:]) { (result, keyValuePair: (key: String, value: Any)) -> [String: String] in
            var newResult = result
            if let keyString = keyValuePair.key as? String, let valueString = keyValuePair.value as? String { // improve
                newResult[keyString] = valueString
            }

            return newResult
        }
    }
}
