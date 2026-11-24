# Florets

## InspectorFloret

The [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html) lets you browse through and share your requests and responses from within the application. Just shake your device (if you are using the default configuration).

## MockFloret

The [MockFloret](https://cauli.works/docs/Classes/MockFloret.html) helps you to easily mock your network requests for tests or to reproduce a bug. You can can use it to record the responses for later mocking and even is compatible to the Format used in the [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html). By default it reads the mocks from a `MockFloret` folder in the app bundle. Use the `mockFolder` parameter to read them from another folder, e.g. a different set of mocks or, when running in the simulator, a folder on your Mac. The [MockFloret guide](https://cauli.works/docs/mockfloret.html) describes how recording and mocking work and the format the mocks are stored in.

## NoCacheFloret

The [NoCacheFloret](https://cauli.works/docs/Classes/NoCacheFloret.html) modifies the designatedRequest and the response of a record to prevent returning cached data or writing data to the cache.

## FindReplaceFloret

The [FindReplaceFloret](https://cauli.works/docs/Classes/FindReplaceFloret.html) can be used to easily replace any part of a request or response by using a [RecordModifier](https://cauli.works/docs/Structs/RecordModifier.html)

## MapRemoteFloret

The [MapRemoteFloret](https://cauli.works/docs/Classes/MapRemoteFloret.html) can modify the url of a request before the request is performed. This is esp. helpful when using a staging or testing server.

## HTTPBodyStreamFloret

The [HTTPBodyStreamFloret](https://cauli.works/docs/Classes/HTTPBodyStreamFloret.html) reads a request's `httpBodyStream` and sets its data as `httpBody`, so the body can be inspected in the `InspectorFloret` or modified by other florets. Bodies larger than its `maximumConvertedByteSize` are kept as a stream.

## NetworkUsageFloret

The [NetworkUsageFloret](https://cauli.works/docs/Classes/NetworkUsageFloret.html) measures how much the app uses the network and suggests how to use less. It counts the bytes sent and received over the network, the size after decompression, cache hits, protocols and connection reuse, per host and per endpoint (paths with ids are grouped, e.g. `/users/:id`). It counts from the moment it is created until `reset()`, and can export the usage as CSV or JSON.

In the Cauli menu it shows the totals, the hints and the hosts by data received. Every hint opens a screen with the affected endpoints and how to fix it, and every host lists its endpoints, tagged with the hints about them. Reset and Share are in the navigation bar.

```swift
let usage = NetworkUsageFloret()
let cauli = Cauli([InspectorFloret(), usage])

usage.snapshot.totals.receivedBytes
usage.hints.map(\.title)
```

Every hint comes from a `NetworkUsageRule`, a function of the recorded usage that returns a `NetworkUsageHint` with a summary, the affected endpoints, an estimated saving and how to fix it. The built-in rules find uncompressed responses and uploads, duplicate requests, responses that can't be cached, large payloads, hosts only using HTTP/1.1 and hosts that reuse few connections. Their thresholds can be adjusted, and your own rules are listed with them:

```swift
struct ImageFormatRule: NetworkUsageRule {
    let identifier = "legacy-image-format"

    func evaluate(_ usage: NetworkUsageSnapshot) -> NetworkUsageHint? {
        let keys = Set(usage.transfers.filter { $0.responseContentType == "image/png" }.map(\.endpointKey))
        guard !keys.isEmpty else { return nil }
        return NetworkUsageHint(ruleIdentifier: identifier, severity: .info, title: "PNG images",
                                summary: "\(keys.count) endpoints serve PNG images",
                                affectedEndpoints: usage.endpoints(withKeys: keys),
                                estimatedSavingBytes: nil, howToFix: "Serve WebP or AVIF instead.")
    }
}

let usage = NetworkUsageFloret(rules: NetworkUsageFloret.defaultRules + [ImageFormatRule(), LargePayloadRule(minimumBodyBytes: 200_000)])
```

Only requests Cauli intercepts are counted. Requests excluded by the `RecordSelector`, or passed through because they exceed its limit, are missing.

## NetworkConditionsFloret

The [NetworkConditionsFloret](https://cauli.works/docs/Classes/NetworkConditionsFloret.html) simulates slow and unreliable networks. Every host can have its own `NetworkCondition`, all other hosts use the default. A condition adds latency, limits the download and upload bandwidth, and lets a share of the requests fail with a network error or an HTTP status. The presets are LTE, 3G, Edge, Very bad network and Offline.

The floret remembers every host the app connected to, across app starts, so you can pick a host's condition in the Cauli menu before the next request. The menu shows what is throttled, and "Stop All Throttling" resets every condition.

```swift
let conditions = NetworkConditionsFloret()
let cauli = Cauli([InspectorFloret(), conditions])
conditions.defaultCondition = .threeG
conditions.setCondition(.offline, for: "api.example.com")
```

Add your own conditions in code. They are listed in the menu with the presets:

```swift
let slowAPI = NetworkCondition(name: "Slow API", latency: 2, downloadBytesPerSecond: 20_000,
                               failureRate: 0.2, failure: .httpStatus(503))
let conditions = NetworkConditionsFloret(conditions: NetworkCondition.presets + [slowAPI])
```

Cauli hands each response to the app at once, so bandwidth limits are simulated as a delay. Only requests Cauli intercepts are affected.

