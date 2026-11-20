# MockFloret

The [MockFloret](https://cauli.works/docs/Classes/MockFloret.html) answers requests with responses stored on disk. You can record real responses, put them into your app, and use them in tests, for demos or to reproduce a bug. This guide describes how recording and mocking work together and the format the mocks are stored in.

## Recording and mocking

1. **Record** the responses you need:
   ```swift
   let mockFloret = MockFloret(mode: .record)
   let cauli = Cauli([mockFloret])
   cauli.run()
   ```
   Every HTTP response Cauli intercepts (see the `RecordSelector` of your `Configuration`) is stored in a `MockFloret` folder in the documents directory. Failed requests aren't recorded. The exact path is printed to the console as `recording to ...`.
2. **Copy** that `MockFloret` folder into your app. When you drag it to Xcode, select "Create folder references", so the folder structure is kept.
3. **Mock** the requests:
   ```swift
   let mockFloret = MockFloret(mode: .mock(forced: false))
   ```
   For every request, the `MockFloret` looks for a stored response. If it finds one, the request is answered with it and never reaches the network. If it doesn't, the request is performed as usual. With `.mock(forced: true)`, it's answered with a 404 response instead.

By default, mocks are read from the `MockFloret` folder in the main bundle. Use `mockFolder` to read them from somewhere else, e.g. a different set of mocks in the bundle or, when running in the simulator, a folder on your Mac:

```swift
let mockFloret = MockFloret(mockFolder: URL(fileURLWithPath: "/Users/me/Desktop/mock-data"))
```

## Folder structure

```
MockFloret/
├── GET_http_ip_jsontest_com_/
│   └── b014744502154b59cdd3ed4c2f21c8b6/
│       ├── record.json
│       └── response.data
└── POST_https_cauli_works_api_florets/
    └── 6f1ed002ab5595859014ebf0951522d9/
        ├── record.json
        ├── designatedRequest.data
        └── response.data
```

### Request folders

The first level contains one folder per request. Its name is the HTTP method and the full url, joined with `_`, where every run of characters other than letters, digits and `_` is replaced by a single `_`:

| Request | Folder |
|---|---|
| `GET http://ip.jsontest.com/` | `GET_http_ip_jsontest_com_` |
| `POST https://cauli.works/api/florets?page=2` | `POST_https_cauli_works_api_florets_page_2` |

A request is mocked if a folder with its name exists. The request is compared as it reaches the `MockFloret`, so florets before it in the list, like a `MapRemoteFloret`, can change which folder is used. Only the method and the url are compared: headers and the body of the request are ignored. The query is part of the url, so `?a=1&b=2` and `?b=2&a=1` are different requests.

### Response folders

Each request folder contains one folder per response. The name of a response folder doesn't matter when mocking. If there are several, the `MockFloret` picks one of them at random for every request.

When recording, the folder is named after a hash of the response: of its `ETag` header, or, if there is none, of its status code and body. A response that was already recorded for that request isn't stored again.

### Files

| File | Content |
|---|---|
| `record.json` | The request, the response and its metadata, see below. Required. |
| `response.data` | The body of the response, exactly as it was received. Missing if the response had no body. |
| `originalRequest.data`, `designatedRequest.data` | The body of the request, if it had one. Only kept for reference, they aren't used for mocking. |

## record.json

`record.json` is a serialized [Record](https://cauli.works/docs/Structs/Record.html). Here is the recorded response from the example app, shortened:

```json
{
  "identifier" : "AEA4F334-2185-41E5-B024-687FC2F7053F",
  "originalRequest" : {
    "url" : "http:\/\/ip.jsontest.com\/",
    "httpMethod" : "GET",
    "allHTTPHeaderFields" : {},
    "cachePolicy" : 0,
    "timeoutInterval" : 60,
    "allowsCellularAccess" : true,
    "httpShouldHandleCookies" : true,
    "httpShouldUsePipelining" : false
  },
  "designatedRequest" : { "…" : "same fields as originalRequest" },
  "result" : {
    "urlResponseRepresentable" : {
      "httpURLResponse" : {
        "url" : "http:\/\/ip.jsontest.com\/",
        "statusCode" : 200,
        "headerFields" : {
          "Content-Type" : "application\/json; charset=ISO-8859-1",
          "Content-Length" : "23"
        }
      }
    },
    "dataFilename" : "response.data"
  },
  "requestStarted" : 566833670.01283097
}
```

| Field | Description |
|---|---|
| `identifier` | A UUID identifying the record. |
| `originalRequest` | The request as the app sent it. |
| `designatedRequest` | The request as it was performed, after florets modified it. If it had a body, `bodyFilename` names the file with it. |
| `result` | The response, see below. |
| `requestStarted`, `responseReceived` | Optional timestamps, as seconds since January 1, 2001. |

The `url`, `cachePolicy`, `timeoutInterval`, `allowsCellularAccess`, `httpShouldHandleCookies` and `httpShouldUsePipelining` fields of both requests are required to read the file, even though only the `result` is used for mocking.

The `result` is one of:

- **A response.** `urlResponseRepresentable` contains either an `httpURLResponse` with `url`, `statusCode` and `headerFields`, or, for non-HTTP responses, a `urlResponse` with `url`, `mimeType`, `expectedContentLength` and `textEncodingName`. `dataFilename` names the file with the body, usually `response.data`.
- **An error**, with the `domain`, `code` and `userInfo` of an `NSError`. Mocking it makes the request fail with that error:
  ```json
  "result" : { "domain" : "NSURLErrorDomain", "code" : -1009, "userInfo" : {} }
  ```

## Writing mocks by hand

The easiest way to create a mock is to record a similar response and edit it:

* Change the body by replacing `response.data`. Update or remove the `Content-Length` header in `record.json` if the size changes.
* Change the status code or headers in `result.urlResponseRepresentable.httpURLResponse`.
* To mock another url, copy the response folder into a request folder named after that url, as described above.

Records shared from the [InspectorFloret](https://cauli.works/docs/Classes/InspectorFloret.html) use the same format. Put the shared files into a response folder to use them as a mock.

## Manual mappings

If a request can't be matched by its url, e.g. because the url contains a timestamp, map it manually and load the response with `resultForPath(_:)`. The path is relative to the mock folder:

```swift
mockFloret.addMapping(forUrlPath: "/api/florets") { request, floret in
    floret.resultForPath("default/florets")
}
```

Mappings are checked before the request folders. The folder they point to can be named freely, like `default/florets` above, as long as it contains a `record.json`.
