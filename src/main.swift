import Foundation
import SwiftUI

func main() {
  let image = NSImage(byReferencingFile: "./assets/tesla.png")!
  let pixelBuffer = image.colorPixelBuffer()

  // double check pixel buffer
  CGImage.create(from: pixelBuffer)!.savePng(URL(fileURLWithPath: "output.png"))

  // let encoder = VTH264Encoder(width: image!.width, height: image!.height)
}

main()
