# Florets

## InspectorFloret

The [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html) lets you browse through and share your requests and responses from within the application. Just shake your device (if you are using the default configuration).

## MockFloret

The [MockFloret](https://cauli.works/docs/Classes/MockFloret.html) helps you to easily mock your network requests for tests or to reproduce a bug. You can can use it to record the responses for later mocking and even is compatible to the Format used in the [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html). By default it reads the mocks from a `MockFloret` folder in the app bundle. Use the `mockFolder` parameter to read them from another folder, e.g. a different set of mocks or, when running in the simulator, a folder on your Mac.

## NoCacheFloret

The [NoCacheFloret](https://cauli.works/docs/Classes/NoCacheFloret.html) modifies the designatedRequest and the response of a record to prevent returning cached data or writing data to the cache.

## FindReplaceFloret

The [FindReplaceFloret](https://cauli.works/docs/Classes/FindReplaceFloret.html) can be used to easily replace any part of a request or response by using a [RecordModifier](https://cauli.works/docs/Structs/RecordModifier.html)

## MapRemoteFloret

The [MapRemoteFloret](https://cauli.works/docs/Classes/MapRemoteFloret.html) can modify the url of a request before the request is performed. This is esp. helpful when using a staging or testing server.

## HTTPBodyStreamFloret

The [HTTPBodyStreamFloret](https://cauli.works/docs/Classes/HTTPBodyStreamFloret.html) reads a request's `httpBodyStream` and sets its data as `httpBody`, so the body can be inspected in the `InspectorFloret` or modified by other florets. Bodies larger than its `maximumConvertedByteSize` are kept as a stream.
