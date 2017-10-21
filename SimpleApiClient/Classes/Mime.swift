public struct Mime {
  public enum Text: String {
    case plain, html, css, javascript
  }
  public enum Image: String {
    case gif, png, jpeg, bmp, webp
  }
  public enum Audio: String {
    case midi, mpeg, webm, ogg, wav
  }
  public enum Video: String {
    case webm, ogg
  }
  public enum Application: String {
    case octetStream, pdf, pkcs12, vndMsPowerpoint = "vnd.mspowerpoint", xhtmlXml = "xhtml+xml", xml
  }
}
