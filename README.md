# ![Cauli](https://cauli.works/logo.png)

[![Tests](https://github.com/cauliframework/cauli/workflows/Tests/badge.svg)](https://github.com/cauliframework/cauli/actions)
[![SPM Compatible](https://camo.githubusercontent.com/86f8561418bbd6240d5c39dbf80b83a3dc1e85e69fe58da808f0168194dcc0d3/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f5377696674504d2d436f6d70617469626c652d627269676874677265656e2e737667)](https://github.com/cauliframework/cauli/blob/develop/Package.swift)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/cauliframework/cauli/blob/develop/LICENSE)
[![Jazzy documentation](https://cauli.works/docs/badge.svg)](https://cauli.works/docs/)

Cauli is a network debugging framework featuring a plugin infrastructure to hook into selected request and responses as well as recording and displaying performed requests. It provides a wide range of possibilities. For example from [inspecting](https://cauli.works/docs/florets.html#InspectorFloret) network traffic to [mock](https://cauli.works/docs/florets.html#MockFloret) UnitTests. Missing something fancy? How about [writing your own Plugin](https://cauli.works/docs/writing-your-own-plugin.html).

## Features

🌏 Hooks into the [URL Loading System](https://cauli.works/docs/frequently-asked-questions.html)  
🧩 [Existing](https://cauli.works/docs/florets.html) set of Plugins (Florets)  
🔧 [Extensible](https://cauli.works/docs/writing-your-own-plugin.html) Plugin Infrastructure

### Documentation

* [Architecture](https://cauli.works/docs/architecture.html)
* [Configuring Cauli](https://cauli.works/docs/configuring-cauli.html)
* [Plugins / Florets](https://cauli.works/docs/florets.html)
* [Writing Your Own Plugin / Floret](https://cauli.works/docs/writing-your-own-plugin.html)
* [MockFloret](https://cauli.works/docs/mockfloret.html)
* [Frequently Asked Questions](https://cauli.works/docs/frequently-asked-questions.html)

## Getting Started

### Installation

#### [Swift Package Manager](https://swift.org/package-manager/)

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. Once you have your Swift package set up, add the following to your `Package.swift` file.

```swift
dependencies: [
    .package(url: "https://github.com/cauliframework/cauli.git", from: "1.1")
]
```

### Setup

Add an `import Cauliframework` to your `AppDelegate` and call the `run` function on the shared instance in `application(_:didFinishLaunchingWithOptions:)`. Make sure to call `run` before instantiating any `URLSession`. Otherwise Cauli can't intercept network requests and create any records.

```swift
import Cauliframework
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Cauli.shared.run()
        // perform your usual application setup
        return true
    }
}
```

This will configure Cauli to hook into every request, setup the core florets (plugins) ([InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html)) and configures a shake gesture for the Cauli UI.

## Built-in Florets

* [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html) lets you browse through and share your requests and responses from within the application. Just shake your device (if you are using the default configuration).
* [MockFloret](https://cauli.works/docs/Classes/MockFloret.html) mocks your network requests, e.g. for tests or to reproduce a bug. It can also record responses for later mocking.
* [NoCacheFloret](https://cauli.works/docs/Classes/NoCacheFloret.html) modifies requests and responses so that no cached data is returned or written to the cache.
* [FindReplaceFloret](https://cauli.works/docs/Classes/FindReplaceFloret.html) replaces any part of a request or response, using a [RecordModifier](https://cauli.works/docs/Structs/RecordModifier.html).
* [MapRemoteFloret](https://cauli.works/docs/Classes/MapRemoteFloret.html) changes the url of a request before it is performed, e.g. to use a staging or testing server.
* [HTTPBodyStreamFloret](https://cauli.works/docs/Classes/HTTPBodyStreamFloret.html) turns a request's `httpBodyStream` into `httpBody` data, so the body can be inspected and modified.

Pass the florets you want to use when creating your own `Cauli` instance:

```swift
let cauli = Cauli([InspectorFloret(), NoCacheFloret()])
cauli.run()
```

For more information read [Plugins / Florets](https://cauli.works/docs/florets.html).

## Writing your own Floret

A floret can process requests and responses, provide its own UI, or both:

* **[InterceptingFloret](https://cauli.works/docs/Protocols/InterceptingFloret.html)** is called before a request is sent (`willRequest`) and after its response arrived (`didRespond`). It can modify the `Record` before passing it on.
* **[DisplayingFloret](https://cauli.works/docs/Protocols/DisplayingFloret.html)** provides a view controller, which is shown in the Cauli UI. It has access to the `Cauli` instance and thus to its [Storage](https://cauli.works/docs/Protocols/Storage.html) of recorded requests.

This example prints every request and response to the console:

```swift
import Cauliframework

final class LoggingFloret: InterceptingFloret {
    var enabled = true
    var description: String? { "Prints every request and response to the console." }

    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let request = record.designatedRequest
        print("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "-")")
        completionHandler(record)
    }

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let url = record.designatedRequest.url?.absoluteString ?? "-"
        switch record.result {
        case .result(let response)?:
            let statusCode = (response.urlResponse as? HTTPURLResponse).map { String($0.statusCode) } ?? "-"
            print("← \(statusCode) \(url) (\(response.data?.count ?? 0) bytes)")
        case .error(let error)?:
            print("← failed \(url): \(error.localizedDescription)")
        case nil:
            break
        }
        completionHandler(record)
    }
}
```

`willRequest` and `didRespond` are called on a background thread. Always call the completion handler exactly once, with the original or a modified record, otherwise the request won't continue.

Add it like any other floret, e.g. `Cauli([InspectorFloret(), LoggingFloret()])`. For more details read [Writing Your Own Plugin / Floret](https://cauli.works/docs/writing-your-own-plugin.html).

## Contributing
Please read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License
Cauli is available under the [MIT license](LICENSE).
