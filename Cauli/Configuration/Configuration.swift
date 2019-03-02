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

import Foundation

/// The Configuration is used to configure Cauli at initialization time.
/// The `Configuration.standard` is a sensibly chosen configuration set.
public struct Configuration {

    /// The default Configuration.
    ///
    /// - Configuration:
    ///   - recordSelector: Only records to a maximum of 5 MB are considered.
    ///   - enableShakeGesture: The shake gesture is enabled.
    ///   - storageCapacity: The storage capacity is limited to 50 records,.
    ///   - preStorageRecordModifier: A `RecordModifier` that can modify records before they are stored.
    public static let standard = Configuration(
        recordSelector: RecordSelector.max(bytesize: 5 * 1024 * 1024),
        enableShakeGesture: true,
        storageCapacity: .records(50)
    )

    /// Defines if a Record should be handled. This can be used to only select Records by a specific domain, a filetype, a maximum filesize or such.
    ///
    /// ## Examples
    /// ```swift
    /// // Only records for the domain cauli.works are selected.
    /// RecordSelector { $0.originalRequest.url?.host == "cauli.works" }
    ///
    /// // Only records with a response body of max 10 MB are selected.
    /// RecordSelector.max(bytesize: 10 * 1024 * 1024)
    /// ```
    public let recordSelector: RecordSelector

    /// If `enableShakeGesture` is set to true, Cauli will try to hook into the
    /// `UIWindow.motionEnded(:UIEvent.EventSubtype, with: UIEvent?)` function
    /// to display the Cauli UI whenever the device is shaken.
    /// If that function is overridden the Cauli automatism doesn't work. In that case, you can
    /// use the `Cauli.viewController()` function to display that ViewController manually.
    public let enableShakeGesture: Bool

    /// The `storageCapacity` defines the capacity of the storage.
    public let storageCapacity: StorageCapacity

    /// This `RecordModifier` allows the `Storage` to modify records before they are stored.
    /// This allows you to change details of a record before it is passed along to a presentation floret, like for example the `InspectorFloret`.
    public var preStorageRecordModifier: RecordModifier?

    /// Creates a new `Configuration` with the given parameters. Please check the
    /// properties of a `Configuration` for their meaning.
    public init(recordSelector: RecordSelector, enableShakeGesture: Bool, storageCapacity: StorageCapacity, preStorageRecordModifier: RecordModifier? = nil) {
        self.recordSelector = recordSelector
        self.enableShakeGesture = enableShakeGesture
        self.storageCapacity = storageCapacity
        self.preStorageRecordModifier = preStorageRecordModifier
    }
}
