import Alamofire
import RxSwift

public protocol SimpleApi {
  var path: String { get }
  var parameters: Parameters { get }
  var headers: HTTPHeaders { get }
  var method: HTTPMethod { get }
}

public extension SimpleApi {
  public var parameters: Parameters {
    return [:]
  }
  
  public var headers: HTTPHeaders {
    return [:]
  }
}

public protocol Unwrappable {
  var responseKeyPath: String { get }
}

public protocol Mockable {
  var mockResponse: MockResponse { get }
}

public protocol Uploadable {
  var multiParts: [MultiPart] { get }
}
