# Configuring Cauli

To get started Cauli offers a shared instance already setup and ready to use but you can instantiate and configure your own.

## Instantiating Cauli

Please make sure you create your Cauli instance as early as possible, especially before any request is started so Cauli can intercept every request. If you don't want to start Cauli at the beginning just don't call the `run` function. Check the [Architecture](Architecture) for more details.
 
```swift
let cauli = Cauli([ InspectorFloret() ], configuration: Configuration(isShakeGestureEnabled: false))
```

Please check the [Docs](https://cauli.works/docs/Structs.html#/s:5Cauli13ConfigurationV) for all configuration options.

## Start / Stop Cauli

```swift
cauli.run()
cauli.pause()
```

## Manually Display the Cauli UI

If you don't want to use the shake gesture you can display the Cauli UI manually.

```swift
// Disable the shake gesture using the Configuration
let cauli = Cauli([ InspectorFloret() ], configuration: Configuration(isShakeGestureEnabled: false))

// Create the Cauli ViewController to display it manually
let cauliViewController = cauli.viewController()
```