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

@testable import Cauliframework
import UIKit
import XCTest

/// Temporary: renders the Cauli menu while running and while paused into `SCREENSHOT_DIR`.
final class ScreenshotTests: XCTestCase {

    func testTakeScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("SCREENSHOT_DIR is not set")
        }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let florets: [Floret] = [
            InspectorFloret(),
            MockFloret(),
            NoCacheFloret(),
            FindReplaceFloret(name: "Redact tokens", description: "Replaces the Authorization header before records are stored.")
        ]
        let cauli = Cauli(florets, configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .unlimited))

        for (state, isRunning) in [("running", true), ("paused", false)] {
            if isRunning {
                cauli.run()
            } else {
                cauli.pause()
            }
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = render(CauliViewController(cauli: cauli), style: style)
                let file = URL(fileURLWithPath: directory).appendingPathComponent("\(device)-menu-\(state)-\(style == .dark ? "dark" : "light").png")
                try XCTUnwrap(image.pngData()).write(to: file)
            }
        }
        cauli.pause()
    }

    private func render(_ viewController: UIViewController, style: UIUserInterfaceStyle) -> UIImage {
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window.overrideUserInterfaceStyle = style
        window.rootViewController = UINavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(1))
        window.layoutIfNeeded()
        // The test host doesn't draw the window on screen, so render the layers directly.
        let format = UIGraphicsImageRendererFormat(for: window.traitCollection)
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
            window.traitCollection.performAsCurrent {
                UIColor.systemBackground.setFill()
                context.fill(window.bounds)
                window.layer.render(in: context.cgContext)
            }
        }
        window.isHidden = true
        return image
    }

}
