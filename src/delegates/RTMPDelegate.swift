import CoreMedia
import Foundation

class RTMPDelegate: EncoderDelegate {
  var url: URL?
  var rtmp = RTMP()
  var i = 0

  convenience init(url: URL) {
    self.init()
    self.url = url
  }

  init() {
    RTMP_LogSetLevel(RTMP_LOGDEBUG)

    // Show librtmp version
    let version = RTMP_LibVersion()
    let versionString = String(format: "0x%08x", version) // RTMP_LibVersion: 0x00020300
    print("RTMP_LibVersion: \(versionString)")

    RTMP_Init(&rtmp)
  }

  func open() {
    RTMPEXT_Open(&rtmp)
    /*
     _ = url!.absoluteString.withCString { ptr in
       RTMP_SetupURL(&rtmp, UnsafeMutablePointer<CChar>(mutating: ptr))
     }

     RTMP_EnableWrite(&rtmp)

     if RTMP_Connect(&rtmp, nil) != 0 {
       print("Connect FAILED:", url!)
     }

     if RTMP_ConnectStream(&rtmp, 0) != 0 {
       print("ConnectStream FAILED")
     }
     */
  }

  func close() {
    RTMP_Close(&rtmp)
  }

  func onVideoMetadata(sps: Data, pps: Data) {
    var data = Array(repeating: 0x00, count: 256)

    data.withUnsafeMutableBufferPointer { buffer in
      var count = 0
      sps.withUnsafeBytes { spsBuffer in
        pps.withUnsafeBytes { ppsBuffer in
          print("sps: ", sps, "pps: ", pps)
          count = RTMPEXT_MakeVideoMetadataTag(spsBuffer.baseAddress, spsBuffer.count, ppsBuffer.baseAddress, ppsBuffer.count, buffer.baseAddress, buffer.count)
        }
      }
      RTMP_Write(&rtmp, buffer.baseAddress, Int32(count))
    }
  }

  func onVideoSample(_ sampleBuffer: CMSampleBuffer) {
    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    let dataLength = CMBlockBufferGetDataLength(dataBuffer)
    print("on video sample: ", dataLength)
    var dataPointer: UnsafeMutablePointer<Int8>?
    CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &dataPointer)

    let timestamp = i * 40
    i += 1
    var data = Data(count: 16 + dataLength)
    data.withUnsafeMutableBytes { buffer in
      let count = RTMPEXT_MakeVideoNALUTag(Int32(timestamp), dataPointer!, dataLength, buffer.baseAddress, buffer.count)

      RTMP_Write(&rtmp, buffer.baseAddress, Int32(count))
    }
    // print(data.hexString)
  }
}
