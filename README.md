# SimpleApiClient

[![CI Status](http://img.shields.io/travis/jaychang0917/SimpleApiClient.svg?style=flat)](https://travis-ci.org/jaychang0917/SimpleApiClient)
[![Version](https://img.shields.io/cocoapods/v/SimpleApiClient.svg?style=flat)](http://cocoapods.org/pods/SimpleApiClient)
[![License](https://img.shields.io/cocoapods/l/SimpleApiClient.svg?style=flat)](http://cocoapods.org/pods/SimpleApiClient)
[![Platform](https://img.shields.io/cocoapods/p/SimpleApiClient.svg?style=flat)](http://cocoapods.org/pods/SimpleApiClient)

A configurable api client based on Alamofire4 and RxSwift4 for iOS

## Table of Contents
* [Basic Usage](#basic_usage)
* [Unwrap Response by KeyPath](#unwrap_keypath)
* [Upload File(s)](#upload)
* [Serial / Parallel Calls](#serial_parallel_calls)
* [Retry Interval / Exponential backoff](#retry)
* [Call Cancellation](#call_cancel)
* [Mock Response](#mock_response)

## Installation

SimpleApiClient is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SimpleApiClient'
```

## <a name=basic_usage>Basic Usage</a>
### Step 1
Configurate the api client
```swift
let config = SimpleApiClient.Config(
baseUrl: "https://api.github.com",
defaultParameters: ["foo": "bar"],
defaultHeaders: ["foo": "bar"],
timeout: 120, // default is 60s
certificatePins: [
CertificatePin(hostname: "https://api.github.com", certificateUrl: Bundle.main.url(forResource: "serverCert", withExtension: "cer")!)
],
errorMessageKeyPath: "message",
jsonDecoder: JSONDecoder(),  // default is JSONDecoder()
isMockResponseEnabled: true, // default is false
logHandler: { request, response in
...
},
errorHandler: { error in
// you can centralize the handling of general error here
switch error {
case .authenticationError(let code, let message):
...
case .clientError(let code, let message):
...
case .serverError(let code, let message):
...
case .networkError(let source):
...
case .sslError(let source):
...
case .uncategorizedError(let source):
...
}
}
)

let githubClient = SimpleApiClient(config: config)
```
### Step 2
Create the API
```swift
import SimpleApiClient

struct GetRepoApi: SimpleApi {
let user: String
let repo: String

var path: String {
return "/repos/\(user)/\(repo)"
}

var method: HTTPMethod {
return .get
}

// optional
var parameters: Parameters {
return [:]
}

// optional
var headers: HTTPHeaders {
return [:]
}
}

extension SimpleApiClient {
func getRepo(user: String, repo: String) -> Observable<Repo> {
return request(api: GetRepoApi(user: user, repo: repo))
}
}
```

### Step 3
Use `observe()` to enqueue the call, do your stuff in corresponding parameter block. All blocks run on main thread by default and are optional.
```swift
githubClient.getRepo(user: "foo", repo: "bar")
.observe(
onStart: { print("show loading") },
onEnd: { print("hide loading") },
onSuccess: { print("sucess: \($0)") },
onError: { print("error: \($0)" }
)
```

## <a name=unwrap_keypath>Unwrap Response by KeyPath</a>
Sometimes the api response includes metadata that we don't need, but in order to map the response we create a wrapper class and make the function return that wrapper class.
This approach leaks the implementation of service to calling code.

Assuming the response json looks like the following:
```xml
{
total_count: 33909,
incomplete_results: false,
foo: {
bar: {
items: [
{
login: "foo",
...
}
...
]
}
}
}
```
And you only need the `items` part, implement `Unwrappable` to indicate which part of response you want.
```swift
struct GetUsersApi: SimpleApi, Unwrappable {
...

var responseKeyPath: String {
return "foo.bar.items"
}
}

// then your response will be a list of User
extension SimpleApiClient {
func getUsers(query: String) -> Observable<[User]> {
return request(api: GetUsersApi(query: query))
}
}
```

## <a name=upload>Upload File(s)</a>
To upload file(s), make the API implements `Uploadable` to provide `Multipart`s
```swift
struct UploadImageApi: SimpleApi, Uploadable {
...

var multiParts: [MultiPart] {
let multiPart = MultiPart(data: UIImageJPEGRepresentation(image, 1)!, name: "imagefile", filename: "image.jpg", mimeType: "image/jpeg")
return [multiPart]
}
}

extension SimpleApiClient {
func uploadImage(image: UIImage) -> Observable<Image> {
return request(api: UploadImageApi(image))
}
}
```

## <a name=serial_parallel_calls>Serial / Parallel Calls</a>
### Serial
```swift
githubClient.foo()
.then { foo in githubClient.bar(foo.name) }
.observe(...)
```

### Serial then Parallel
```swift
githubClient.foo()
.then { foo in githubClient.bar(foo.name) }
.thenAll { bar in
(githubClient.baz(bar.name), githubClient.qux(bar.name)) // return a tuple
}
.observe(...)
```

### Parallel
```swift
SimpleApiClient.all(
githubApi.foo(),
githubApi.bar()
)
.observe(...)
```

### Parallel then Serial
```swift
SimpleApiClient.all(
githubApi.foo(),
githubApi.bar()
).then { array -> // the return type is Array<Any>, you should cast them, e.g. let foo = array[0] as! Foo
githubApi.baz()
}.observe(...)
```

## <a name=retry>Retry Interval / Exponential backoff</a>
```kotlin
githubClient.getUsers("foo")
.retry(delay: 5, maxRetryCount: 3) // retry up to 3 times, each time delays 5 seconds
.retry(exponentialDelay: 5, maxRetryCount: 3) // retry up to 3 times, each time delays 5^n seconds, where n = {1,2,3}
.observe(...)
```

## <a name=call_cancel>Call Cancellation</a>
### Auto Call Cancellation
The call will be cancelled when the object is deallocated.
```swift
githubClient.getUsers("foo")
.cancel(when: self.rx.deallocated)
.observe(...)
```

### Cancel call manually
```swift
let call = githubClient.getUsers("foo").observe(...)

call.cancel()
```

## <a name=mock_response>Mock Response</a>
To enable response mocking, set `SimpleApiClient.Config.isMockResponseEnabled` to `true` and make the API implements `Mockable` to provide `MockResponse`.

### Mock sample json data
To make the api return a successful response with provided json

```swift
struct GetUsersApi: SimpleApi, Mockable {
...

var mockResponse: MockResponse {
let file = Bundle.main.url(forResource: "get_users", withExtension: "json")!
return MockResponse(jsonFile: file)
}
}
```

### Mock status
To make the api return a client side error with provided json
```swift
struct GetUsersApi: SimpleApi, Mockable {
...

var mockResponse: MockResponse {
let file = Bundle.main.url(forResource: "get_users_error", withExtension: "json")!
return MockResponse(jsonFile: file, status: .clientError)
}
}
```

the parameter `jsonFile` of `MockResponse` is optional, you can set the status only, then you receive empty string.

Possible `Status` values:
```swift
public enum Status {
case success
case authenticationError
case clientError
case serverError
case networkError
case sslError
}
```

To mock a response with success status only, you should return `Observable<Nothing>`.
```swift
struct DeleteRepoApi: SimpleApi, Mockable {
...

var mockResponse: MockResponse {
return MockResponse(status: .success)
}
}

extension SimpleApiClient {
func deleteRepo(id: String) -> Observable<Nothing> {
return request(api: DeleteRepoApi(id: id))
}
}
```


## Author

jaychang0917, jaychang0917@gmail.com

## License

SimpleApiClient is available under the MIT license. See the LICENSE file for more info.

