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

/// The MapRemoteFloret can modify the url of a request before the request is performed.
/// This is esp. helpful to change the app to use a staging or testing server.
///
/// The MapRemoteFloret can only modify the url of a request. If you need to update headers please use the `FindReplaceFloret`.
///
/// Example configuration. For more examples check the `Mapping` documentation.
/// ```swift
/// let httpsifyMapping = Mapping(name: "https-ify", sourceLocation: MappingLocation(scheme: "http"), destinationLocation: MappingLocation(scheme: "https"))
/// let mapLocal = Mapping(name: "map local", sourceLocation: MappingLocation(), destinationLocation: MappingLocation(host: "localhost")
/// let floret = MapRemoteFloret(mappings: [httpsifyMapping, mapLocal])
/// Cauli([floret])
/// ```
public class MapRemoteFloret {
    
    internal var userDefaults = UserDefaults()
    public var enabled: Bool {
        set {
            userDefaults.setValue(newValue, forKey: "Cauli.MapRemoteFloret.enabled")
        }
        get {
            userDefaults.bool(forKey: "Cauli.MapRemoteFloret.enabled")
        }
    }
    public var description: String? {
        "The MapRemoteFloret can modify the url of a request before performed. \n Currently \(enabledMappings.count) mappings are enabled."
    }
    
    private let mappings: [Mapping]
    private var enabledMappings: Set<String> {
        set {
            userDefaults.setValue(Array(newValue), forKey: "Cauli.MapRemoteFloret.enabledMappings")
        }
        get {
            guard let mappings = userDefaults.array(forKey: "Cauli.MapRemoteFloret.enabledMappings") as? [String] else { return [] }
            return Set(mappings)
        }
    }
    
    public init(mappings: [Mapping]) {
        self.mappings = mappings
    }
    
    func isMappingEnabled(_ mapping: Mapping) -> Bool {
        enabledMappings.contains(mapping.name)
    }
    
    func setMapping(_ mapping: Mapping, enabled: Bool) {
        if enabled {
            enabledMappings.insert(mapping.name)
        } else {
            enabledMappings.remove(mapping.name)
        }
    }
}

extension MapRemoteFloret: InterceptingFloret {
    public func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let mappedRecord = mappings.filter { enabledMappings.contains($0.name) }.reduce(record) { (record, mapping) -> Record in
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
