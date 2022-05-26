import CoreGraphics
import UniformTypeIdentifiers
import VideoToolbox

public extension CGImage {
  internal static func create(from cvPixelBuffer: CVPixelBuffer?) -> CGImage? {
    guard let pixelBuffer = cvPixelBuffer else {
      return nil
    }

    var image: CGImage?
    VTCreateCGImageFromCVPixelBuffer(
      pixelBuffer,
      options: nil,
      imageOut: &image
    )
    return image
  }

  func pngData() -> Data? {
    let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
    if let destination = CGImageDestinationCreateWithData(cfdata, UTType.png.identifier as CFString, 1, nil) {
      CGImageDestinationAddImage(destination, self, nil)
      if CGImageDestinationFinalize(destination) {
        return cfdata as Data
      }
    }

    return nil
  }

  func savePng(_ url: URL) {
    let data = pngData()
    try! data?.write(to: url)
  }
}
