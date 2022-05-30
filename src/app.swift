import CoreMedia
import Foundation
import SwiftUI

@main
class App {
  static let shared = App()
  var timer: Timer?
  var encoder: VTH264Encoder?
  var delegate: EncoderDelegate?

  init() {
    // delegate = H264FileDelegate(url: URL(fileURLWithPath: "build/clip.h264"))
    delegate = RTMPDelegate(url: URL(string: "rtmp://")!)
  }

  func run() {
    delegate!.open()

    let image = NSImage(byReferencingFile: "./assets/tesla.png")!
    guard let pixelBuffer = image.colorPixelBuffer() else { return }
    print(pixelBuffer.pixelFormatName())
    print(pixelBuffer.width, pixelBuffer.height)

    // double check pixel buffer
    // CGImage.create(from: pixelBuffer)!.savePng(URL(fileURLWithPath: "output.png"))

    encoder = VTH264Encoder(delegate, width: pixelBuffer.width, height: pixelBuffer.height)
    encoder!.start()

    timer = Timer.scheduledTimer(withTimeInterval: encoder!.interval.seconds, repeats: true) { _ in
      self.encoder!.encode(pixelBuffer)
    }

    RunLoop.main.run()
  }

  func close() {
    delegate!.close()
    encoder!.stop()
    timer!.invalidate()
    exit(0)
  }

  static func main() {
    signal(SIGINT) { _ in App.shared.close() }
    App.shared.run()
  }
}
