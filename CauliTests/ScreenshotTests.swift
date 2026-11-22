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

/// Temporary: renders the main screens in light and dark mode into `SCREENSHOT_DIR`.
final class ScreenshotTests: XCTestCase {

    func testTakeScreenshots() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("SCREENSHOT_DIR is not set")
        }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let mapRemoteFloret = MapRemoteFloret(mappings: [
            Mapping(name: "Staging", sourceLocation: MappingLocation(host: "api.cauli.works"), destinationLocation: MappingLocation(host: "staging.cauli.works")),
            Mapping(name: "Local server", sourceLocation: MappingLocation(host: "api.cauli.works"), destinationLocation: MappingLocation(protocol: .http, host: "localhost", port: 8080))
        ])
        let florets: [Floret] = [
            InspectorFloret(),
            mapRemoteFloret,
            MockFloret(),
            NoCacheFloret(),
            FindReplaceFloret(name: "Redact tokens", description: "Replaces the Authorization header before records are stored.")
        ]
        let cauli = Cauli(florets, configuration: Configuration(recordSelector: .all(), enableShakeGesture: false, storageCapacity: .unlimited))
        let records = [
            record("GET", "/florets?page=2", status: 200),
            record("POST", "/florets", status: 201),
            record("GET", "/florets/42", status: 404),
            record("DELETE", "/florets/7", status: 500),
            record("GET", "/organizations/cauliframework/members", status: 304)
        ]
        records.reversed().forEach { cauli.storage.store($0) }

        let screens: [(String, () -> UIViewController)] = [
            ("1-cauli-menu", { CauliViewController(cauli: cauli) }),
            ("2-records", { InspectorFloret().viewController(cauli) }),
            ("3-record-details", { RecordTableViewController(records[0]) }),
            ("4-body-viewer", { PlaintextPrettyPrinter(string: Self.prettyJSON) }),
            ("5-mappings", { mapRemoteFloret.viewController(cauli) })
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

    private func record(_ method: String, _ path: String, status: Int) -> Record {
        let url = URL(string: "https://api.cauli.works\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer ****", forHTTPHeaderField: "Authorization")
        var record = Record(request)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        record.result = .result(Response(response, data: Self.prettyJSON.data(using: .utf8)))
        record.requestStarted = Date()
        record.responseReceived = Date().addingTimeInterval(0.3)
        return record
    }

    private static let prettyJSON = """
    {
      "florets" : [
        { "name" : "InspectorFloret", "enabled" : true },
        { "name" : "MapRemoteFloret", "enabled" : false }
      ],
      "page" : 2,
      "total" : 42
    }
    """
}
