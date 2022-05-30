import CoreMedia
import Foundation

class H264FileDelegate: EncoderDelegate {
  var url: URL?
  private var h264file: FileHandle?
  private let startCode: [Int8] = [0x00, 0x00, 0x00, 0x01]
  private let startCodeData: Data?

  init(url: URL) {
    self.url = url
    startCodeData = Data(bytes: startCode, count: 4)

    // let home = FileManager.default.homeDirectoryForCurrentUser
    // let clip = home.appendingPathComponent("/Desktop/output.h264")
    try? FileManager.default.removeItem(at: self.url!)
    if FileManager.default.createFile(atPath: self.url!.path, contents: nil, attributes: nil) {
      h264file = try? FileHandle(forWritingTo: url)
    }
  }

  func open() {}

  func close() {
    do { try h264file?.close() } catch {}
  }

  func onVideoMetadata(sps: Data, pps: Data) {
    guard let f = h264file else { return }

    f.write(startCodeData!)
    f.write(sps)
    f.write(startCodeData!)
    f.write(pps)

    print("write sps and pps")
  }

  func onVideoSample(_ sampleBuffer: CMSampleBuffer) {
    guard let f = h264file else { return }

    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    var lengthAtOffset = 0
    var totalLength = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    if CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: &lengthAtOffset, totalLengthOut: &totalLength, dataPointerOut: &dataPointer) == noErr {
      var bufferOffset = 0
      let AVCCHeaderLength = 4

      while bufferOffset < (totalLength - AVCCHeaderLength) {
        var NALUnitLength: UInt32 = 0
        // first four character is NALUnit length
        memcpy(&NALUnitLength, dataPointer?.advanced(by: bufferOffset), AVCCHeaderLength)

        // big endian to host endian. in iOS it's little endian
        NALUnitLength = CFSwapInt32BigToHost(NALUnitLength)

        let data = NSData(bytes: dataPointer?.advanced(by: bufferOffset + AVCCHeaderLength), length: Int(NALUnitLength))
        // [UInt8]
        // let data = Data(bytes: dataPointer?.advanced(by: bufferOffset + AVCCHeaderLength), count: Int(NALUnitLength))

        f.write(startCodeData!)
        f.write(data as Data)
        print("write NALU")

        // move forward to the next NAL Unit
        bufferOffset += Int(AVCCHeaderLength)
        bufferOffset += Int(NALUnitLength)
      }
    }
  }
}
