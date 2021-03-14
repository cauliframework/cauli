<p align="center">
    <img src="https://cauli.works/logo.png" alt="Cauli Logo" title="Cauli Logo" width="500" /><br/>
    <br/>
	<a href="https://travis-ci.org/cauliframework/cauli">
		<img src="https://travis-ci.org/cauliframework/cauli.svg?branch=develop" alt="Build Status" title="Build Status"/>
	</a>
	<a href="https://cocoapods.org/pods/Cauliframework">
		<img src="https://img.shields.io/cocoapods/v/Cauliframework.svg?style=flat-square" alt="CocoaPods Compatible" title="CocoaPods Compatible"/>
	</a>
	<a href="https://github.com/cauliframework/cauli/blob/develop/LICENSE">
		<img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License MIT" title="License MIT"/>
	</a>
	<a href="https://cauli.works/docs/">
		<img src="https://cauli.works/docs/badge.svg" alt="Jazzy documentation" title="Jazzy documentation"/>
	</a>
</p>

Cauli is a framework designed to make network debugging easier. It uses a plugin infrastructure with simple ways to inspect your traffic as well as complex solutions to modify and record your request and responses. Cauli hooks into the [URL Loading System](https://cauli.works/docs/frequently-asked-questions.html), thus you can see every request your app performs, even those from third party dependencies.
Missing something fancy? How about [writing your own Plugin](https://cauli.works/docs/writing-your-own-plugin.html).

### Documentation

* [Architecture](https://cauli.works/docs/architecture.html)
* [Configuring Cauli](https://cauli.works/docs/configuring-cauli.html)
* [Plugins / Florets](https://cauli.works/docs/florets.html)
* [Writing Your Own Plugin / Floret](https://cauli.works/docs/writing-your-own-plugin.html)
* [Frequently Asked Questions](https://cauli.works/docs/frequently-asked-questions.html)

## Getting Started

### Installation
#### [CocoaPods](https://cocoapods.org)

Use the following in your Podfile.

```ruby
pod 'Cauliframework'
```

Then run `pod install`.

#### [Carthage](https://github.com/Carthage/Carthage)

Use the following in your Cartfile.

```swift
github "cauliframework/cauli"
```

#### [Swift Package Manager](https://swift.org/package-manager/)

Use the following in your `Package.swift` file.

```swift
dependencies: [
    .package(url: "https://github.com/cauliframework/cauli.git", from: "1.0.1")
]
```

### Setup

Add an `import Cauliframework` to your `AppDelegate` and call the `run` function on the shared instace in the `application(:, didFinishLaunchingWithOptions:)`. Make sure to call `run` before instantiating any `URLSession`. Otherwise Cauli can't intercept network requests and create any records.

```swift
import Cauliframework

public class AppDelegate: UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Cauli.shared.run()
        // perform your usual application setup
        return true
    }
}
```

This will configure Cauli to hook into every request, setup the core florets (plugins) ([InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html)) and configures a shake gesture for the Cauli UI.

## Built-in Florets you can use

#### InspectorFloret

The [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html) lets you browse through and share your requests and responses from within the application. Just shake your device (if you are using the default configuration).

#### MockFloret

The [MockFloret](https://cauli.works/docs/Classes/MockFloret.html) helps you to easily mock your network requests for tests or to reproduce a bug. You can can use it to record the responses for later mocking and even is compatible to the Format used in the [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html).

#### NoCacheFloret

The [NoCacheFloret](https://cauli.works/docs/Classes/NoCacheFloret.html) modifies the designatedRequest and the response of a record to prevent returning cached data or writing data to the cache.

#### FindReplaceFloret

The [FindReplaceFloret](https://cauli.works/docs/Classes/FindReplaceFloret.html) can be used to easily replace any part of a request or response by using a [RecordModifier](https://cauli.works/docs/Classes/FindReplaceFloret/RecordModifier.html)

#### MapRemoteFloret

The [MapRemoteFloret](https://cauli.works/docs/Classes/MapRemoteFloret.html) can modify the url of a request before the request is performed. This is especially helpful when using a staging or testing server.

## Custom Floret

To log requests in the Xcode debugger you can create a custom Intercepting Floret.

```swift
class LoggingFloret: InterceptingFloret {

    var enabled: Bool = true

    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let request = record.originalRequest
        print("REQUEST for: \(request.httpMethod!) \(request.url!)")
        completionHandler(record)
    }

    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void) {
        let request = record.originalRequest
        if case .result(let response) = record.result, let httpResponse = response.urlResponse as? HTTPURLResponse {
            print("RESPONSE of: \(request.httpMethod!) \(request.url!)")
            print("HTTP status \(httpResponse.statusCode), Request took \(Date().timeIntervalSince(record.requestStarted!)) seconds")
            print(String(data: response.data!, encoding: .utf8)!)
        }
        completionHandler(record)
    }
}
```

Setup Cauli in AppDelegate and start a request.

```swift
@main class AppDelegate: UIResponder, UIApplicationDelegate {

    var cauli: Cauli?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        cauli = Cauli([LoggingFloret()], configuration: .standard)
        cauli?.run()
        URLSession.shared.dataTask(with: URL(string: "https://foo.bar/baz")!).resume()
        return true
    }
}
```

And the debugger prints this.

```
REQUEST for: GET https://foo.bar/baz
RESPONSE of: GET https://foo.bar/baz
{"foo":"bar","baz":true}
```

## Contributing
Please read [CONTRIBUTING](CONTRIBUTING.md) for details.

## License
Cauli is available under the [MIT license](LICENSE).
