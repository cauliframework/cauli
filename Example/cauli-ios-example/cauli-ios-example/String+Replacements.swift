//
//  NSRegularExpression+Replacements.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 07.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

extension String {
    public mutating func replaceOcurrences(of expression: NSRegularExpression, with template: String) {
        let modified = replacingOcurrences(of: expression, with: template)
        self = modified
    }
    
    public func replacingOcurrences(of expression: NSRegularExpression, with template: String) -> String {
        let range = NSRange(self.startIndex..., in: self)
        return expression.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
    }
}
