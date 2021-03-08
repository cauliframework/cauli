//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public class MapRemoteFloret {
    
    public var enabled: Bool = false
    public var description: String? {
        "The MapRemoteFloret can modify the url of a request before performed. \n Currently \(enabledMappingUuids.count) mappings are enabled."
    }
    
    private let mappings: [Mapping]
    private var enabledMappingUuids: Set<UUID> = []
    
    public init(mappings: [Mapping]) {
        self.mappings = mappings
    }
    
    func isMappingEnabled(_ mapping: Mapping) -> Bool {
        enabledMappingUuids.contains(mapping.uuid)
    }
    
    func setMapping(_ mapping: Mapping, enabled: Bool) {
        if enabled {
            enabledMappingUuids.insert(mapping.uuid)
        } else {
            enabledMappingUuids.remove(mapping.uuid)
        }
    }
}

extension MapRemoteFloret: InterceptingFloret {
    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let mappedRecord = mappings.filter { enabledMappingUuids.contains($0.uuid) }.reduce(record) { (record, mapping) -> Record in
            guard let requestUrl = record.designatedRequest.url, mapping.sourceLocation.matches(url: requestUrl) else { return record }
            var record = record
            let updatedUrl = mapping.destinationLocation.updating(url: requestUrl)
            record.designatedRequest.url = updatedUrl
            return record
        }
        completionHandler(mappedRecord)
    }
    
    public func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        completionHandler(record)
    }
}

extension MapRemoteFloret: DisplayingFloret {
    public func viewController(_ cauli: Cauli) -> UIViewController {
        MappingsListViewController(mapRemoteFloret: self, mappings: mappings)
    }
}
