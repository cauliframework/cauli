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

/// Temporary: renders the screens of the NetworkConditionsFloret into `SCREENSHOT_DIR`.
final class ScreenshotTests: XCTestCase {

    func testTakeScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("SCREENSHOT_DIR is not set")
        }
        let suiteName = "ScreenshotTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let slowAPI = NetworkCondition(name: "Slow API", latency: 2, downloadBytesPerSecond: 20_000, uploadBytesPerSecond: 20_000, failureRate: 0.2, failure: .httpStatus(503))
        let floret = NetworkConditionsFloret(conditions: NetworkCondition.presets + [slowAPI], userDefaults: userDefaults)
        for host in ["cdn.example.org", "auth.example.com", "analytics.example.net", "images.example-cdn.com", "api.example.com"] {
            floret.willRequest(Record(URLRequest(url: URL(string: "https://\(host)/")!))) { _ in }
        }
        floret.setCondition(.edge, for: "api.example.com")
        floret.setCondition(.offline, for: "analytics.example.net")
        floret.setCondition(.noThrottling, for: "auth.example.com")
        let cauli = Cauli([InspectorFloret(), floret, NoCacheFloret()], configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .records(1)))

        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let screens: [(String, () -> UIViewController)] = [
            ("1-menu", { CauliViewController(cauli: cauli) }),
            ("2-conditions", { NetworkConditionsViewController(floret: floret) }),
            ("3-picker", { NetworkConditionPickerViewController(floret: floret, host: "api.example.com") })
        ]
        for (name, makeViewController) in screens {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let image = render(makeViewController(), style: style)
                let file = URL(fileURLWithPath: directory).appendingPathComponent("\(device)-\(name)-\(style == .dark ? "dark" : "light").png")
                try XCTUnwrap(image.pngData()).write(to: file)
            }
        }
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
