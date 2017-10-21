import Alamofire

struct ErrorResponse: Error {
  let data: Data?
  let error: Error
  init(data: Data? = nil, error: Error) {
    self.data = data
    self.error = error
  }
}

// MARK: -

class ErrorConsumer {
  typealias ErrorHandler = (Error) -> Void
  typealias SACError = SimpleApiClient.Error
  
  private var data: Data?
  private var error: Error
  private var errorHandler: ErrorHandler
  
  init(errorResponse: ErrorResponse, errorHandler: @escaping ErrorHandler) {
    self.data = errorResponse.data
    self.error = errorResponse.error
    self.errorHandler = errorHandler
  }
  
  static func transform(error: Error, data: Data?) -> SimpleApiClient.Error {
    var result = SACError.uncategorizedError(source: error)
    
    if let e = error as? AFError, let code = e.responseCode {
      var message = ""
      if let keyPath = ApiManager.errorMessageJsonKeyPath, let data = data {
        do {
          let errorJson = try JSONSerialization.jsonObject(with: data, options: [])
          message = (errorJson as AnyObject).value(forKeyPath: keyPath) as! String
        } catch {
        }
      }
      
      switch code {
      case 401, 403:
        result = SACError.authenticationError(code: code, message: message)
      case 400...499:
        result = SACError.clientError(code: code, message: message)
      case 500...599:
        result = SACError.serverError(code: code, message: message)
      default:
        break
      }
    }
    
    if let e = error as? URLError {
      switch e.code {
      case .notConnectedToInternet:
        result = SACError.networkError(source: e)
      case URLError.Code.serverCertificateUntrusted:
        result = SACError.sslError(source: e)
      default:
        break
      }
    }
    
    // mock error
    if let e = error as? SACError {
      switch e {
      case .networkError(let source):
        result = SACError.networkError(source: source)
      case .sslError(let source):
        result = SACError.sslError(source: source)
      default:
        break
      }
    }
    
    return result
  }
  
  func accept() {
    errorHandler(ErrorConsumer.transform(error: error, data: data))
  }
}
