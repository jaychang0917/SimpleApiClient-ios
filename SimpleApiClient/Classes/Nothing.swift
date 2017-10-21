import Foundation

public struct Nothing: Decodable, CustomStringConvertible {
  public var description: String {
    return "SimpleApiClient.Nothing"
  }
  
  public init() {
  }
}
