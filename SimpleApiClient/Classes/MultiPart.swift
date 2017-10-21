import Foundation

public struct MultiPart {
  public let data: Data
  public let name: String
  public let filename: String
  public let mimeType: String
  
  public init(data: Data, name: String, filename: String, mimeType: String) {
    self.data = data
    self.name = name
    self.filename = filename
    self.mimeType = mimeType
  }
}
