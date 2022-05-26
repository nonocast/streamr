import CoreGraphics
import CoreImage
import ImageIO

public extension CIImage {
  func convertToCGImage() -> CGImage? {
    let context = CIContext(options: nil)
    if let cgImage = context.createCGImage(self, from: extent) {
      return cgImage
    }
    return nil
  }

  func data() -> Data? {
    convertToCGImage()?.pngData()
  }
}
