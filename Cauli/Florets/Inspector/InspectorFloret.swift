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

/// The InspectorFloret lets you browse through and share your requests and responses from within the application. Just open `Cauli`s viewController.
///
/// You can
/// * browse through all stored `Records`.
/// * inspect details of a `Record`.
/// * share details of a `Record`.
/// * filter `Record`s by the request URL.
public class InspectorFloret: DisplayingFloret {

    public var description: String? = "Tap to inspect network requests and responses. Data is recorded as long as Cauli is enabled."

    private let formatter: InspectorFloretFormatterType

    /// Public initalizer to create an instance of the `InspectorFloret`.
    public init() {
        self.formatter = InspectorFloretFormatter()
    }

    /// Public initializer to create an instace of the `InspectorFloret` with a custom
    /// formatter. See `InspectorFloretFormatterType` for further details.
    /// - Parameter formatter: The `InspectorFloretFormatterType` to be used.
    public init(formatter: InspectorFloretFormatterType) {
        self.formatter = formatter
    }

    public func viewController(_ cauli: Cauli) -> UIViewController {
        InspectorTableViewController(cauli, formatter: formatter)
    }

}
