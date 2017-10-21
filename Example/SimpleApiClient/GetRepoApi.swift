import Foundation
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
}

extension SimpleApiClient {
  func getRepo(user: String, repo: String) -> Observable<Repo> {
    return request(api: GetRepoApi(user: user, repo: repo))
  }
}

