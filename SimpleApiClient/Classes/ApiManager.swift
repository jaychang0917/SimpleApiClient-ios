import Alamofire
import RxSwift

fileprivate typealias SACError = SimpleApiClient.Error

class ApiManager {
  private let config: SimpleApiClient.Config
  private let manager: SessionManager
  static var errorMessageJsonKeyPath: String?
  
  init(config: SimpleApiClient.Config) {
    self.config = config
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = config.timeout
    configuration.timeoutIntervalForResource = config.timeout
    configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
    manager = SessionManager(configuration: configuration, serverTrustPolicyManager: ApiManager.serverTrustPolicyManager(config))
    ApiManager.errorMessageJsonKeyPath = config.errorMessageKeyPath
  }
  
  func request<Api: SimpleApi, Result: Decodable>(api: Api) -> Observable<Result> {
    if let mockableApi = api as? Mockable, config.isMockResponseEnabled {
      let unwrappableApi = api as? Unwrappable
      return mockRequest(mockableApi.mockResponse, keyPath: unwrappableApi?.responseKeyPath).subscribeOnBackground().observeOnMain()
    } else {
      return httpRequest(api).observeOnMain()
    }
  }
}

// MARK: - Mock request

extension ApiManager {
  fileprivate func mockRequest<Result: Decodable>(_ mockResponse: MockResponse, keyPath: String?) -> Observable<Result> {
    if mockResponse.status == .success {
      return successMockRequest(mockResponse.jsonFile, keyPath: keyPath)
    } else {
      return errorMockRequest(mockResponse.jsonFile, status: mockResponse.status)
    }
  }
  
  private func successMockRequest<Result: Decodable>(_ file: URL?, keyPath: String?) -> Observable<Result> {
    if let file = file {
      return Observable.create { observer in
        do {
          let data = try Data(contentsOf: file)
          let keyPathData = try data.from(keyPath: keyPath)
          let value = try self.config.jsonDecoder.decode(Result.self, from: keyPathData)
          observer.onNext(value)
          observer.onCompleted()
        } catch {
          observer.onError(ErrorResponse(error: error))
        }
        return Disposables.create()
      }
    } else {
      return Observable.just(Nothing() as! Result)
    }
  }
  
  private func errorMockRequest<Result: Decodable>(_ json: URL?, status: Status) -> Observable<Result> {
    return Observable.create { obverser in
      var httpErrorMessage: String {
        var message = ""
        if let json = json, let keyPath = ApiManager.errorMessageJsonKeyPath {
          do {
            let data = try Data(contentsOf: json)
            message = try data.toJsonObject(keyPath: keyPath) as! String
          } catch {
          }
        }
        return message
      }
      
      let httpErrorResponse: (Int, SACError) -> ErrorResponse = { code, error in
        let error = AFError.responseValidationFailed(reason: AFError.ResponseValidationFailureReason.unacceptableStatusCode(code: code))
        return ErrorResponse(error: error)
      }
      
      switch status {
      case .authenticationError:
        obverser.onError(httpErrorResponse(403, SACError.authenticationError(code: 403, message: httpErrorMessage)))
      case .clientError:
        obverser.onError(httpErrorResponse(400, SACError.clientError(code: 400, message: httpErrorMessage)))
      case .serverError:
        obverser.onError(httpErrorResponse(500, SACError.authenticationError(code: 500, message: httpErrorMessage)))
      case .networkError:
        obverser.onError(ErrorResponse(error: SACError.networkError(source: nil)))
      case .sslError:
        obverser.onError(ErrorResponse(error: SACError.sslError(source: nil)))
      default:
        obverser.onError(ErrorResponse(error: SACError.uncategorizedError(source: nil)))
      }
      
      return Disposables.create()
    }
  }
}

// MARK: - Http request

extension ApiManager {
  fileprivate func httpRequest<Api: SimpleApi, Result: Decodable>(_ api: Api) -> Observable<Result> {
    return Observable.create { observer in
      let completionHandler: (RxSwift.Cancelable, Any?, Data?, ErrorResponse?) -> Void = { call, json, data, errorResponse in
        if call.isDisposed {
          return
        }
        
        if let errorResponse = errorResponse {
          observer.onError(errorResponse)
          self.config.errorHandler?(ErrorConsumer.transform(error: errorResponse.error, data: errorResponse.data))
          return
        }
        
        if let json = json {
          do {
            var newData = data!
            if let unwrappableApi = api as? Unwrappable {
              let unwrappedJson = (json as AnyObject).value(forKeyPath: unwrappableApi.responseKeyPath)
              newData = try JSONSerialization.data(withJSONObject: unwrappedJson!)
            }
            let value = try self.config.jsonDecoder.decode(Result.self, from: newData)
            observer.onNext(value)
            observer.onCompleted()
          } catch {
            observer.onError(ErrorResponse(error: error))
          }
        }
      }
      
      var request: DataRequest!
      let call: RxSwift.Cancelable = Disposables.create {
        request.cancel()
      }
      
      if let uploadableApi = api as? Uploadable {
        self.upload(baseUrl: self.config.baseUrl, path: api.path, method: api.method, parameters: api.parameters, headers: api.headers, parts: uploadableApi.multiParts, requestCallback: ({ request = $0 })) { json, data, errorResponse in
          completionHandler(call, json, data, errorResponse)
        }
      } else {
        request = self.reqeust(baseUrl: self.config.baseUrl, path: api.path, method: api.method, parameters: api.parameters, headers: api.headers) { json, data, errorResponse in
          completionHandler(call, json, data, errorResponse)
        }
      }
      
      return call
      }
  }
}

extension ApiManager {
  fileprivate func reqeust(baseUrl: String, path: String, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders, completion: @escaping (Any?, Data?, ErrorResponse?) -> Void) -> DataRequest {
    var newParams = config.defaultParameters
    for (k, v) in parameters {
      newParams.updateValue(v, forKey: k)
    }
    
    var newHeaders = config.defaultHeaders
    for (k, v) in headers {
      newHeaders.updateValue(v, forKey: k)
    }
    
    var request: DataRequest!
    request = manager.request(toUrl(baseUrl, path), method: method, parameters: newParams, encoding: method == .get ? URLEncoding.default : JSONEncoding.default, headers: newHeaders)
      .validate()
      .responseJSON(queue: DispatchQueue.global()) { response in
        switch response.result {
        case .success(let json):
          completion(json, response.data, nil)
        case .failure(let error):
          completion(nil, nil, ErrorResponse(data: response.data, error: error))
        }
        
        self.config.logHandler?(request!, response)
    }
    
    return request
  }
}

extension ApiManager {
  fileprivate func upload(baseUrl: String, path: String, method: HTTPMethod, parameters: Parameters, headers: HTTPHeaders, parts: [MultiPart], requestCallback: @escaping (UploadRequest) -> Void, completion: @escaping (Any?, Data?, ErrorResponse?) -> Void) {
    manager.upload(
      multipartFormData: { multipartFormData in
        for part in parts {
          multipartFormData.append(part.data, withName: part.name, fileName: part.filename, mimeType: part.mimeType)
        }
        
        for (key, value) in parameters {
          multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
        }
      },
      to: toUrl(baseUrl, path),
      method: method,
      headers: headers,
      encodingCompletion: { encodingResult in
        switch encodingResult {
        case .success(let upload, _, _):
          requestCallback(upload)
          upload.responseJSON { response in
            switch response.result {
            case .success(let json):
              completion(json, response.data, nil)
            case .failure(let error):
              completion(nil, nil, ErrorResponse(data: response.data, error: error))
            }
            self.config.logHandler?(upload, response)
          }
        case .failure(let error):
          completion(nil, nil, ErrorResponse(error: error))
        }
      }
    )
  }
}

// MARK: - Certificate public key pinning

extension ApiManager {
  fileprivate static func serverTrustPolicyManager(_ config: SimpleApiClient.Config) -> ServerTrustPolicyManager? {
    guard !config.certificatePins.isEmpty else { return nil}
   
    let getCert: (CertificatePin) -> SecCertificate = { pin in
      let data = try! Data(contentsOf: pin.certificateUrl)
      return SecCertificateCreateWithData(nil, data as CFData)!
    }
    
    let getPublicKey: (SecCertificate) -> SecKey = { cert in
      let policy = SecPolicyCreateBasicX509()
      var trust: SecTrust?
      SecTrustCreateWithCertificates(cert, policy, &trust)
      return SecTrustCopyPublicKey(trust!)!
    }

    let policies: [String: ServerTrustPolicy] = config.certificatePins.reduce(into: [:]) { combined, pin in
      let key = getPublicKey(getCert(pin))
      let policy = ServerTrustPolicy.pinPublicKeys(publicKeys: [key], validateCertificateChain: true, validateHost: true)
      combined[pin.hostname] = policy
    }
    
    return ServerTrustPolicyManager(policies: policies)
  }
}

// MARK: -

private func toUrl(_ baseUrl: String, _ path: String) -> String {
  return (path.hasPrefix("http://") || path.hasPrefix("https://")) ? path : baseUrl + path
}
