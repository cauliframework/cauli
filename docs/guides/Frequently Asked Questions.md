# Frequently Asked Questions

## Can I use Cauli in my production builds?
Cauli is designed for developing purposes. Even if it doesn't use any private API we recommend against using it in a production environment.

## What kind of network traffic is considered?
Cauli hooks into the [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system). This means it only considers network traffic of `URLSessions` as well as traffic from [legacy URL Loading Systems](https://developer.apple.com/documentation/foundation/url_loading_system/legacy_url_loading_systems) such as `NSURLConnection` or `UIWebView`.  
Currently only the `URLSession.default` and `URLSessions` initialised with the `URLSessionConfiguration.default` are supported.

## Why are WKWebView and SFSafariViewController not supported?

WKWebView runs out of process, meaning it is not using the URL loading system of your application and thus are not passing through the `URLProtocol`. In iOS 11 Apple added the [`setURLSchemeHandler:forURLScheme:`](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/2875766-seturlschemehandler?language=objc) on the [WKWebViewConfiguration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration?language=objc) which can be used to intercept requests, but it is not possible to register a custom `WKURLSchemeHandler` for http or https schemes. There are [alternative solutions](https://github.com/wilddylan/WKWebViewWithURLProtocol/blob/master/WKWebViewWithURLProtocol/NSURLProtocol%2BWKWebViewSupport.m) which leverage private API, but Cauli should stay private API free.
`SFSafariViewController` runs out of process as well and is sandboxed. There are no APIs to intercept requests.

## How can I modify Records before they are displayed in displaying florets, like the InspectorFloret?
You may want to modify certain aspects of recorded requests or responses before they are displayed in the `Cauli` view controller. For example you have some confidential information in the request headers, like an API key or auth token that you don't want to expose.

Displaying florets fetch their data from a `Storage` before it is displayed. This gives you the opportunity to modify the data (a `Record`) before it is stored. You can use a `RecordModifier` for this, that is passed to your `Cauli` `Configuration` on init:

```swift
let recordModifier = RecordModifier(keyPath: \Record.designatedRequest) { designatedRequest -> (URLRequest) in
    let headerKey = "X-AUTH-NAME"
    var request = designatedRequest
    request.setValue(String(repeating: "*", count: (request.value(forHTTPHeaderField: headerKey) ?? "").count), forHTTPHeaderField: headerKey)
    return request
}

let configuration = Configuration(
    recordSelector: RecordSelector.max(bytesize: 5 * 1024 * 1024),
    enableShakeGesture: true,
    storageCapacity: .records(50),
    preStorageRecordModifier: recordModifier
)

let cauli = Cauli([ InspectorFloret() ], configuration: configuration)
```

This will rewrite all request headers with the key "X-AUTH-NAME" to contain only asterisks, but only after the request was executed with the correct header.
