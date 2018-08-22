//
//  NSError+Cauli.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 22.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

// All errors with code <=100<200 represent internal errors
extension NSError {

    static var internalError: NSError {
        return NSError(domain: "de.brototyp.Cauli", code: 100, userInfo: [:])
    }

    static func onAppendingDataToRecord(with receivedData: Data) -> NSError {
        return NSError(domain: "de.brototyp.Cauli", code: 110, userInfo: ["receivedData": receivedData])
    }

}
