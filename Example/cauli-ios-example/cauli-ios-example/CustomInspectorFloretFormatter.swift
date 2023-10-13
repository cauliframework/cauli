//
//  CustomInspectorFloretFormatter.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 25.09.23.
//  Copyright © 2023 brototyp.de. All rights reserved.
//

import Cauliframework

class CustomInspectorFloretFormatter: InspectorFloretFormatterType {

    private let defaultFormatter = InspectorFloretFormatter()

    func listFormattedData(for record: Cauliframework.Record) -> Cauliframework.InspectorFloret.RecordListFormattedData {
        guard case .error(let error) = record.result else {
            return defaultFormatter.listFormattedData(for: record)
        }
        let defaultData = defaultFormatter.listFormattedData(for: record)
        let newMethod = "\(defaultData.method) | \(error.domain).\(error.code)"
        return Cauliframework.InspectorFloret.RecordListFormattedData(method: newMethod, path: defaultData.path, time: defaultData.time, status: defaultData.status, statusColor: defaultData.statusColor)
    }

    func recordMatchesQuery(record: Cauliframework.Record, query: String) -> Bool {
        defaultFormatter.recordMatchesQuery(record: record, query: query)
    }
}
