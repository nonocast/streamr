import SwiftUI

// https://gist.github.com/DennisWeidmann/7c4b4bb72062bd1a40c714aa5d95a0d7
extension NSImage {
  // return the NSImage as a color 32bit Color CVPixelBuffer
  // function used by depthPixelBuffer and disparityPixelBuffer to actually crate the CVPixelBuffer
  func __toPixelBuffer(PixelFormatType: OSType) -> CVPixelBuffer? {
    var bitsPerC = 8
    var colorSpace = CGColorSpaceCreateDeviceRGB()
    var bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue

    // if we need depth/disparity
    if PixelFormatType == kCVPixelFormatType_DepthFloat32 || PixelFormatType == kCVPixelFormatType_DisparityFloat32 {
      bitsPerC = 32
      colorSpace = CGColorSpaceCreateDeviceGray()
      bitmapInfo = CGImageAlphaInfo.none.rawValue | CGBitmapInfo.floatComponents.rawValue
    }
    // if we need mask
    else if PixelFormatType == kCVPixelFormatType_OneComponent8 {
      bitsPerC = 8
      colorSpace = CGColorSpaceCreateDeviceGray()
      bitmapInfo = CGImageAlphaInfo.alphaOnly.rawValue
    }

    // 从NSImage获取的size是Point, 而非pixel
    // let width = Int(size.width)
    // let height = Int(size.height)

    // 从CGImage获取pixel
    // let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    // let width = cgImage!.width
    // let height = cgImage!.height

    // 从NSImage的first rep获取pixel
    guard let rep = representations.first as? NSBitmapImageRep else {
      return nil
    }
    let width = rep.pixelsWide
    let height = rep.pixelsHigh

    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, PixelFormatType, attrs, &pixelBuffer)
    guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
      return nil
    }

    CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(resultPixelBuffer),
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerC,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo)
    else {
      return nil
    }

    // context.translateBy(x: 0, y: height)
    // context.scaleBy(x: 1.0, y: -1.0)

    let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()

    CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    return resultPixelBuffer
  }

  // return the NSImage as a color 32bit Color CVPixelBuffer
  func colorPixelBuffer() -> CVPixelBuffer? {
    return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_32ARGB)
  }

  func maskPixelBuffer() -> CVPixelBuffer? {
    return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_OneComponent8)
  }

  // return NSImage as a 32bit depthData CVPixelBuffer
  func depthPixelBuffer() -> CVPixelBuffer? {
    return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DepthFloat32)
  }

  // return NSImage as a 32bit disparityData CVPixelBuffer
  func disparityPixelBuffer() -> CVPixelBuffer? {
    return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DisparityFloat32)
  }
}
