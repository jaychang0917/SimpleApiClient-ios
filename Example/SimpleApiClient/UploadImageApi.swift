import Foundation
import SimpleApiClient

struct UploadImageApi: SimpleApi, Unwrappable, Uploadable {
  let image: UIImage
  
  var path: String {
    return "https://api.imagga.com/v1/content"
  }

  var headers: HTTPHeaders {
    return ["Authorization": "Basic YWNjXzJlMDZiOWRiNzc1OTdjYzo1ZjZlYTU1Yzg4MjNlMjkzYzU3NmY3OGQ0ODhlMTBmMg=="]
  }
  
  var method: HTTPMethod {
    return .post
  }
  
  var responseKeyPath: String {
    return "uploaded"
  }
  
  var multiParts: [MultiPart] {
    let multiPart = MultiPart(data: UIImageJPEGRepresentation(image, 1)!, name: "imagefile", filename: "image.jpg", mimeType: "image/jpeg")
    return [multiPart]
  }
}

extension SimpleApiClient {
  func uploadImage(_ image: UIImage) -> Observable<[Image]> {
    return request(api: UploadImageApi(image: image))
  }
}

