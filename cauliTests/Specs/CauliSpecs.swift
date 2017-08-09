//
//  CauliSpecs.swift
//  cauli
//
//  Created by Pascal Stüdlein on 07.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

@testable import cauli

import Quick
import Nimble

class CauliSpec: QuickSpec {
    let cauli: Cauli = Cauli()
    let regexFloret: RegexFloret = {
        let regex = try! NSRegularExpression(pattern: ".*tbointeractive.*", options: [])
        return RegexFloret(regex: regex)
    }()
    let rewrite = URLRewriteFloret(replaceMe: "github", withThis: "tbointeractive")
    
    override func spec() {
        describe("canHandle") {
            it("should return false for any request when Cauli has no florets") {
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                expect(self.cauli.canHandle(request)).to(equal(false))
            }
            
            it("should return true for an tbointeractive.com request with RegexFloret") {
                self.cauli.florets = [self.regexFloret]
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                expect(self.cauli.canHandle(request)).to(equal(true))
            }
            
            it("should return false for an google.com request with RegexFloret") {
                self.cauli.florets = [self.regexFloret]
                let request = URLRequest(url: URL(string: "http://google.com")!)
                expect(self.cauli.canHandle(request)).to(equal(false))
            }
        }
    }
}
