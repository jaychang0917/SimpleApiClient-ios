import Foundation

struct User: Decodable {
  let name: String
  let profileUrl: URL
  
  private enum CodingKeys: String, CodingKey {
    case name = "login"
    case profileUrl = "avatar_url"
  }
}
