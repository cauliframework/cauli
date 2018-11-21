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

public struct Configuration {
    public static let standard = Configuration(
        recordSelector: RecordSelector.max(bytesize: 10 * 1024 * 1024),
        enableShakeGesture: true)

    /// Defines if a Record should be handled. This can be used to only select Records by a specific domain, a filetype, a maximum filesize or such.
    public let recordSelector: RecordSelector

    /// If `enableShakeGesture` is set to true, Cauli will try to hook into the
    /// `UIWindow.motionEnded(:UIEvent.EventSubtype, with: UIEvent?)` function
    /// to display the Cauli UI whenever the device is shaken.
    /// If that function is overridden the Cauli automatism doesn't work. In that case, you can
    /// use the `Cauli.viewController()` function to display that ViewController manually.
    public let enableShakeGesture: Bool

    public init(recordSelector: RecordSelector, enableShakeGesture: Bool) {
        self.recordSelector = recordSelector
        self.enableShakeGesture = enableShakeGesture
    }
}
