# Writing your own Plugin

You can write your own plugin if you want to process requests before they get send or responses after they got received.

## Implementing the `Floret` protocol

```swift
protocol Floret {
    
    /// The name of your floret so we can display it in a list.
    var name: String? { get }
    
    // So we can show switches for the Florets in the Cauli UI.
    // There is no need to act on this bool. If it is disabled, the 
    // `willRequest` and `didRespond` functions just aren't called anymore.
    var enabled: Bool { get set }
    
    // Return a ViewController here if you want to or nil if you don't have any UI at all.
    func viewController(_ cauli: Cauli) -> UIViewController?
    
    // These are the two functions that you can use to manipulate a request before it will be sent ...
    func willRequest(_ record: Record) -> Record
    // ... and the response after it is received.
    func didRespond(_ record: Record) -> Record
}
```

## Accessing the storage

Cauli manages the storage of `Record`s. Every request and response passing throigh Cauli is recorded with only a few limitations (TODO: List limitations). When displaying your Florets ViewController you have access to the respective Cauli instance and have access to it's `Storage`.