import Foundation

extension Data {
  func from(keyPath: String?) throws -> Data {
    var result = self
    if let keyPath = keyPath {
      let json = try JSONSerialization.jsonObject(with: result, options: [])
      let unwrappedJson = (json as AnyObject).value(forKeyPath: keyPath)
      result = try JSONSerialization.data(withJSONObject: unwrappedJson!)
    }
    return result
  }
  
  func toJsonObject(keyPath: String?) throws -> Any {
    var result = try JSONSerialization.jsonObject(with: self, options: [])
    if let keyPath = keyPath {
      result = (result as AnyObject).value(forKeyPath: keyPath) as Any
    }
    return result
  }
}
