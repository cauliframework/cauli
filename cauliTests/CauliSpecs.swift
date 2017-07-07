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
    
    override func spec() {
        describe("canHandle") {
            it("should return false for any request when Cauli has no florets") {
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                expect(self.cauli.canHandle(request)).to(equal(false))
            }
            
            it("should return true for an tbointeractive.com request with ComDomainFloret as floret") {
                self.cauli.florets = [ComDomainFloret()]
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                expect(self.cauli.canHandle(request)).to(equal(true))
            }
            
            it("should return false for an tbointeractive.de request with ComDomainFloret as floret") {
                self.cauli.florets = [ComDomainFloret()]
                let request = URLRequest(url: URL(string: "http://tbointeractive.de")!)
                expect(self.cauli.canHandle(request)).to(equal(false))
            }
        }
    }
}
