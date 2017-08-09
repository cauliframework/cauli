//
//  URLRewriteFloretSpec.swift

//  cauli
//
//  Created by Pascal Stüdlein on 15.07.17.
//  Copyright © 2017 TBO Interactive GmbH & Co KG. All rights reserved.
//

@testable import cauli

import Quick
import Nimble

class URLRewriteFloretSpec: QuickSpec {
    let floret = URLRewriteFloret(replaceMe: "github", withThis: "tbointeractive")
    
    override func spec() {
        describe("request for request") {
            it("should return nil request for htw-berlin.de") {
                let request = URLRequest(url: URL(string: "htw-berlin.de")!)
                expect(self.floret.request(for: request)).to(beNil())
            }
            
            it("should return tbointeractive instead of github") {
                let request = URLRequest(url: URL(string: "https://github.com")!)
                let newRequest = self.floret.request(for: request)
                
                expect(newRequest?.url?.absoluteString).to(equal("https://tbointeractive.com"))
            }
        }
        
        describe("response for request") {
            it("should return nil") {
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                
                expect(self.floret.response(for: request)).to(beNil())
            }
        }
        
        describe("response for response") {
            it("should not be nil") {
                let response = URLResponse(url: URL(string: "https://tbointeractive.com")!, mimeType: nil, expectedContentLength: 1234, textEncodingName: nil)
                
                expect(self.floret.response(for: response)).toNot(beNil())
            }
            
            it("should return the same response") {
                let response = URLResponse(url: URL(string: "https://tbointeractive.com")!, mimeType: nil, expectedContentLength: 1234, textEncodingName: nil)
                
                expect(self.floret.response(for: response)).to(equal(response))
            }
        }
        
        describe("data for data") {
            it("should return the same data") {
                let data = "Test".data(using: .utf8)
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                
                expect(self.floret.data(for: data, request: request)).to(equal(data))
            }
        }
        
        describe("error for request") {
            it("should return nil") {
                let request = URLRequest(url: URL(string: "http://tbointeractive.com")!)
                
                expect(self.floret.error(for: request)).to(beNil())
            }
        }
    }
}
