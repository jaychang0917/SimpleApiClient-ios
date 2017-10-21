import RxSwift
import Alamofire

open class SimpleApiClient {
  private var apiManager: ApiManager!
  
  public init(config: SimpleApiClient.Config) {
    apiManager = ApiManager(config: config)
  }
  
  public func request<Api: SimpleApi, Result: Decodable>(api: Api) -> Observable<Result> {
    return apiManager.request(api: api)
  }
}

// MARK: -

public extension SimpleApiClient {
  public struct Config {
    let baseUrl: String
    let defaultParameters: Parameters
    let defaultHeaders: HTTPHeaders
    let timeout: TimeInterval
    let certificatePins: [CertificatePin]
    let errorMessageKeyPath: String?
    let jsonDecoder: JSONDecoder
    let isMockResponseEnabled: Bool
    let logHandler: ((DataRequest, DataResponse<Any>) -> Void)?
    let errorHandler: ((SimpleApiClient.Error) -> Void)?
    
    public init(baseUrl: String, defaultParameters: Parameters = [:], defaultHeaders: HTTPHeaders = [:], timeout: TimeInterval = 60, certificatePins: [CertificatePin] = [], errorMessageKeyPath: String? = nil, jsonDecoder: JSONDecoder = JSONDecoder(), isMockResponseEnabled: Bool = false, logHandler: ((DataRequest, DataResponse<Any>) -> Void)? = nil, errorHandler: ((SimpleApiClient.Error) -> Void)? = nil) {
      self.baseUrl = baseUrl
      self.defaultParameters = defaultParameters
      self.defaultHeaders = defaultHeaders
      self.timeout = timeout
      self.certificatePins = certificatePins
      self.errorMessageKeyPath = errorMessageKeyPath
      self.jsonDecoder = jsonDecoder
      self.isMockResponseEnabled = isMockResponseEnabled
      self.logHandler = logHandler
      self.errorHandler = errorHandler
    }
  }
}

// MARK: -

public extension SimpleApiClient {
  public class Cancelable {
    private let cancelable: RxSwift.Cancelable
    
    public init(_ cancelable: RxSwift.Cancelable) {
      self.cancelable = cancelable
    }
    
    public func cancel() {
      cancelable.dispose()
    }
    
    public func isCanceled() -> Bool {
      return cancelable.isDisposed
    }
  }
}

// MARK: -

public extension SimpleApiClient {
  public enum Error: Swift.Error {
    case authenticationError(code: Int, message: String)
    case clientError(code: Int, message: String)
    case serverError(code: Int, message: String)
    case networkError(source: Swift.Error?)
    case sslError(source: Swift.Error?)
    case uncategorizedError(source: Swift.Error?)
  }
}

// MARK: -

public typealias Observable = RxSwift.Observable

public typealias Parameters = Alamofire.Parameters

public typealias HTTPHeaders = Alamofire.HTTPHeaders

public typealias HTTPMethod = Alamofire.HTTPMethod

public typealias Cancelable = SimpleApiClient.Cancelable
