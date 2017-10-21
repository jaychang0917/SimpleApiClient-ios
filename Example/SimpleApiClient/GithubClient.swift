import SimpleApiClient

class GithubClient: SimpleApiClient {
  static var shared: GithubClient = {
    let config = SimpleApiClient.Config(
      baseUrl: "https://api.github.com",
      defaultParameters: ["foo": "bar"],
      defaultHeaders: ["foo": "bar"],
      timeout: 120,
      certificatePins: [
        CertificatePin(hostname: "https://api.github.com", certificateUrl: Bundle.main.url(forResource: "serverCert", withExtension: "cer")!)
      ],
      errorMessageKeyPath: "message",
      jsonDecoder: JSONDecoder(),  // default is a JSONDecoder()
      isMockResponseEnabled: true, // default is false
      logHandler: { request, response in
        print("Log: request: \(request.debugDescription)")
      },
      errorHandler: { error in
        switch error {
        case .authenticationError(let code, let message):
          print("authenticationError: \(code) \(message)")
        case .clientError(let code, let message):
          print("clientError: \(code) \(message)")
        case .serverError(let code, let message):
          print("serverError: \(code) \(message)")
        case .networkError(let source):
          print("networkError")
        case .sslError(let source):
          print("sslError")
        case .uncategorizedError(let source):
          print("uncategorizedError")
        }
      }
    )
    return GithubClient(config: config)
  }()
}
