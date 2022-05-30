import Foundation

extension Data {
  var hexString: String {
    return map { String(format: "%02hhx", $0) }.joined(separator: " ")
  }
}
