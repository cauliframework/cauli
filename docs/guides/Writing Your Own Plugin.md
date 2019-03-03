# Writing your own Plugin

You can write your own plugin if you want to process requests before they get send, responses after they got received or if you want to provide an additional UI.

## Before implementing your own Plugin

Before implementing your own idea, you have to decide which Floret base protocol suits the best for you. You can also implement multiple.

**InterceptableFloret:** This protocol let's you process requests and responses.   
**DisplayableFloret:** This protocol let's you create a custom UIViewController for your floret.  
**Floret:** The Floret protocol is the base for the protocols described above. It should not be implemented directly, since there will be no effect.

## Implementing the `InterceptableFloret` protocol

```swift
protocol InterceptableFloret: Floret {

    /// If a InterceptableFloret is disabled both functions `willRequest` and `didRespond` will
    /// not be called anymore. A InterceptableFloret doesn't need to perform any specific action.
    var enabled: Bool { get set }

    /// This function will be called before a request is performed. The InterceptableFlorets will be
    /// called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - inspect the request
    /// - modify the request (update the `designatedRequest`)
    /// - fail the request (set the `result` to `.error()`)
    /// - return a cached or pre-calculated response (set the `result` to `.result()`)
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request before it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func willRequest(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)

    /// This function will be called after a request is performed and the response arrived.
    /// The InterceptableFlorets will be called in the order the Cauli instance got initialized with.
    ///
    /// Using this function you can:
    /// - modify the request
    ///
    /// - Parameters:
    ///   - record: The `Record` that represents the request after it was performed.
    ///   - completionHandler: Call this completion handler exactly once with the
    ///     original or modified `Record`.
    func didRespond(_ record: Record, modificationCompletionHandler completionHandler: @escaping (Record) -> Void)
}
```

## Implementing the `DisplayableFloret` protocol

```swift
/// A DisplayableFloret provides a ViewController for settings or to display any information.
public protocol DisplayableFloret: Floret {
    /// This function is called whenever the Cauli UI will be displayed.
    /// If a Floret needs any UI for configuration or to display data you
    /// can return a ViewController here.
    ///
    /// The default implementation returns nil.
    ///
    /// - Parameter cauli: The Cauli instance this floret will be displayed in. Use this
    ///     instance to access the storage for example.
    /// - Returns: Return a Floret specific ViewController or `nil` if there is none.
    func viewController(_ cauli: Cauli) -> UIViewController
}
```

## Accessing the storage

Cauli manages the storage of `Record`s. Every `Record` selected by the [RecordSelector](https://cauli.works/docs/Structs/RecordSelector.html) is stored in memory. When displaying your DisplayableFlorets ViewController you have access to the respective Cauli instance and thus to it's [Storage](https://cauli.works/docs/Protocols/Storage.html).
