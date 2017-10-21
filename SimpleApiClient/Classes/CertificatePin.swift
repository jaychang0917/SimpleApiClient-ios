import Foundation

public struct CertificatePin {
  public let hostname: String
  public let certificateUrl: URL
  
  public init(hostname: String, certificateUrl: URL) {
    self.hostname = hostname
    self.certificateUrl = certificateUrl
  }
}
