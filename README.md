# Cauli

Cauli is a network debugging framework featuring a plugin infrastructure to hook into selected request and responses as well as recording and displaying performed requests.

**Cauli is designed for developing purposes. Even if it doesn't use any private API we recommend against using it in a production environment**

## Installation
### [CocoaPods](https://cocoapods.org)

Use the following in your Podfile.

```
pod 'Cauli', '~> 1.0'
```

Then run `pod install`. In every file you want to use Cauli, don't forget to import the framework with `import Cauli`.

### Carthage

// TODO: Update before public release

[Carthage](https://github.com/Carthage/Carthage) is a non intrusive way to install Cauli to your project. It makes no changes to your Xcode project and workspace. Add the following to your Cartfile:

```
github "organization/cauli"
```

## Usage
### Setup

Before Cauli can be used the setup function has to be called. To let Cauli inspect all requests it is important to do this before any `URLSession` is created. We recommend to setup Cauli in the `application(:, didFinishLaunchingWithOptions:)` in your `AppDelegate`.

```Swift
import Cauli

public class AppDelegate: UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Cauli.setup()
        // perform your usual application setup
        return true
    }
}
```

### Creating a Cauli instance

Without a Cauli instance no network requests will be intercepted. Once you create a Cauli instace all requests will be recorded and processed by every Floret until the instance is deallocated.

// TODO: Explain Floret usage

```Swift
let florets = [ExampleFloretOne(), ExampleFloretTwo()]
let cauli = Cauli(florets)
```

### Querying the storage

Every Cauli instance has it's own `storage`. The storage holds onto `Record`s. Each record contains one network request and it's response. In order to display and inspect the records you can query the storage.

```Swift
// get the first 10 records
let records = cauli.storage.records(count: 10, after: nil)

// get the next 10 records
let nextRecords = cauli.storage.records(count: 10, after: records.last!)
```

## Details

### Architecture
Cauli will hook into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system) by register a custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol) and swizzling the [URLSessionConfiguration.default](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411560-default) with one, where the [protocolClasses](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411050-protocolclasses) contain the custom [URLProtocol](https://developer.apple.com/documentation/foundation/urlprotocol).

Therefore it's recommended to call `Cauli.setup()` as soon as possible, preferred in the [`application:didFinishLaunchingWithOptions:`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application?language=objc) to ensure that all network requests can be intercepted.

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License
Cauli is available under the [MIT license](LICENSE).
