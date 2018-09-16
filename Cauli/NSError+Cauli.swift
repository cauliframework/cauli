//
//  NSError+Cauli.swift
//  Cauli
//
//  Created by Pascal Stüdlein on 22.08.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

// swiftlint:disable nesting
extension NSError {
    public struct Cauli {
        public let domain = "de.brototyp.cauli"
        public enum Code {}
        public enum UserInfoKey {}
    }

    internal struct CauliInternal {
        internal static let domain = "de.brototyp.cauli.internal"
        internal enum Code: Int {
            case failedToAppendData
        }

        internal enum UserInfoKey: String {
            case data
            case record
        }

        internal static func failedToAppendData(_ data: Data, record: Record) -> NSError {
            return NSError(domain: domain,
                           code: Code.failedToAppendData.rawValue,
                           userInfo: [UserInfoKey.data.rawValue: data, UserInfoKey.record.rawValue: record])
        }
    }
}
