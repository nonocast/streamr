import CoreMedia
import Foundation
import SwiftUI

// TODO: save to h264 (annexb)

var timer: Timer?

func main() {
  let image = NSImage(byReferencingFile: "./assets/tesla.png")!
  guard let pixelBuffer = image.colorPixelBuffer() else { return }
  print(pixelBuffer.pixelFormatName())
  print(pixelBuffer.width, pixelBuffer.height)

  // double check pixel buffer
  CGImage.create(from: pixelBuffer)!.savePng(URL(fileURLWithPath: "output.png"))

  let encoder = VTH264Encoder(width: pixelBuffer.width, height: pixelBuffer.height)
  encoder.start()

  timer = Timer.scheduledTimer(withTimeInterval: encoder.interval.seconds, repeats: true) { _ in
    encoder.encode(pixelBuffer)
  }

  signal(SIGINT) { _ in
    timer?.invalidate()
    exit(0)
  }

  RunLoop.main.run()
}

main()
