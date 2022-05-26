import Combine
import Foundation
import VideoToolbox

class VTH264Encoder {
  var width: Int
  var height: Int
  var fps = 30
  var bitrate: Int { return width * height * 2 * 32 }
  var dataRateLimits: [Int] { return [width * height * 2 * 4, 1] }
  var profile = kVTProfileLevel_H264_Main_AutoLevel
  var maxKeyFrameInterval = 10
  var bframes = false

  private var session: VTCompressionSession?

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  func start() {
    VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                               width: Int32(width),
                               height: Int32(height),
                               codecType: kCMVideoCodecType_H264,
                               encoderSpecification: nil,
                               imageBufferAttributes: nil,
                               compressedDataAllocator: nil,
                               outputCallback: compressionOutputCallback,
                               refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                               compressionSessionOut: &session)
    guard let session = session else { return }

    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: profile)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: true as CFTypeRef)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: maxKeyFrameInterval as CFTypeRef)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate as CFTypeRef)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: dataRateLimits as CFArray)

    VTCompressionSessionPrepareToEncodeFrames(session)
  }

  func stop() {
    //
  }

  func encode(_ imageBuffer: CVImageBuffer) {
    guard let session = session else { return }

    let timestamp = CMTime(value: 1, timescale: 30)

    VTCompressionSessionEncodeFrame(
      session,
      imageBuffer: imageBuffer,
      presentationTimeStamp: timestamp,
      duration: .invalid,
      frameProperties: nil,
      sourceFrameRefcon: nil,
      infoFlagsOut: nil
    )
  }
}

func compressionOutputCallback(outputCallbackRefCon _: UnsafeMutableRawPointer?, sourceFrameRefCon _: UnsafeMutableRawPointer?, status _: OSStatus, infoFlags _: VTEncodeInfoFlags, sampleBuffer _: CMSampleBuffer?) -> Swift.Void {
  print("\(Thread.current): compressionOutputCallback")
}
