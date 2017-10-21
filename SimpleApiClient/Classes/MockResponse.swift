import Foundation

public enum Status {
  case success
  case authenticationError
  case clientError
  case serverError
  case networkError
  case sslError
}

// MARK: -

public struct MockResponse {
  public let jsonFile: URL?
  public let status: Status
  
  public init(jsonFile: URL? = nil, status: Status = Status.success) {
    self.jsonFile = jsonFile
    self.status = status
  }
}
