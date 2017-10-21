import Foundation
import SimpleApiClient

struct GetUsersApi: SimpleApi, Unwrappable, Mockable {
  let query: String
  
  var path: String {
    return "/search/users"
  }
  
  var parameters: Parameters {
    return ["q": query]
  }
  
  var method: HTTPMethod {
    return .get
  }
  
  var responseKeyPath: String {
    return "items"
  }
  
  var mockResponse: MockResponse {
    let file = Bundle.main.url(forResource: "get_users", withExtension: "json")!
    return MockResponse(jsonFile: file)
  }
}

extension SimpleApiClient {
  func getUsers(query: String) -> Observable<[User]> {
    return request(api: GetUsersApi(query: query))
  }
}

