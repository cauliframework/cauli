# Frequently Asked Questions

## Can I use Cauli in my production builds?
Cauli is designed for developing purposes. Even if it doesn't use any private API we recommend against using it in a production environment.

## Why are WKWebView and SFSafariViewController not supported?

WKWebView runs out of process, meaning it is not using the URL loading system of your application and thus are not passing through the `URLProtocol`. In iOS 11 Apple added the [`setURLSchemeHandler:forURLScheme:`](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/2875766-seturlschemehandler?language=objc) on the [WKWebViewConfiguration](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration?language=objc) which can be used to intercept requests, but it is not possible to register a custom `WKURLSchemeHandler` for http or https schemes. There are [alternative solutions](https://github.com/wilddylan/WKWebViewWithURLProtocol/blob/master/WKWebViewWithURLProtocol/NSURLProtocol%2BWKWebViewSupport.m) which leverage private API, but Cauli should stay private API free.
`SFSafariViewController` runs out of process as well and is sandboxed. There are no APIs to intercept requests.
