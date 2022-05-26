import Combine
import Foundation
import VideoToolbox

class VTH264Encoder {
  var width: Int
  var height: Int
  var fps = 1
  var interval: CMTime { return CMTime(value: 1, timescale: CMTimeScale(fps)) }
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
    if let session = session {
      VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
      VTCompressionSessionInvalidate(session)
      self.session = nil
    }
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

extension VTH264Encoder {
  func printSampleInfo(_ sampleBuffer: CMSampleBuffer?) {
    guard let sampleBuffer = sampleBuffer else { return }
    // show sample info
    let desc = CMSampleBufferGetFormatDescription(sampleBuffer)
    let extensions = CMFormatDescriptionGetExtensions(desc!)
    // print("extensions: \(extensions!)")

    let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
    // print("sample count: \(sampleCount)")

    let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)!
    var length = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
    print("length: \(length), dataPointer: \(dataPointer!)")
  }
}

func compressionOutputCallback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                               sourceFrameRefCon _: UnsafeMutableRawPointer?,
                               status: OSStatus,
                               infoFlags: VTEncodeInfoFlags,
                               sampleBuffer: CMSampleBuffer?) -> Swift.Void
{
  // print("\(Thread.current): compressionOutputCallback")
  guard status == noErr else { print("error: \(status)"); return }
  if infoFlags == .frameDropped { print("frame dropped"); return }
  guard let sampleBuffer = sampleBuffer else { print("sampleBuffer is nil"); return }
  guard CMSampleBufferDataIsReady(sampleBuffer) else { print("sampleBuffer data is not ready"); return }

  let encoder: VTH264Encoder = Unmanaged.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
  encoder.printSampleInfo(sampleBuffer)
}
