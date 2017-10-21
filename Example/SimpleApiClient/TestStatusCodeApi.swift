import Foundation
import SimpleApiClient

struct TestStatusCodeApi: SimpleApi {
  var path: String {
    return "https://httpbin.org/status/599"
  }
  
  var method: HTTPMethod {
    return .get
  }
  
  var mockResponse: MockResponse? {
    return MockResponse(status: Status.serverError)
  }
}

extension SimpleApiClient {
  func testStatusCode() -> Observable<Nothing> {
    return request(api: TestStatusCodeApi())
  }
}

