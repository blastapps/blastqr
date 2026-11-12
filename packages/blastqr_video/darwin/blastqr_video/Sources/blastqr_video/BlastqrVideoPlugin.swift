import AVFoundation
import CoreImage

#if os(iOS)
  import Flutter
#else
  import FlutterMacOS
#endif

public class BlastqrVideoPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private var jobs: [Int: VideoCompression] = [:]

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(name: "blastqr_video", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(BlastqrVideoPlugin(channel: channel), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "probe":
      guard let path = call.arguments as? String else {
        result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
        return
      }
      Task {
        do {
          let info = try await VideoCompression.probe(URL(fileURLWithPath: path))
          DispatchQueue.main.async { result(info) }
        } catch {
          DispatchQueue.main.async { result(Self.flutterError(error)) }
        }
      }
    case "compress":
      guard let args = call.arguments as? [String: Any],
        let id = args["id"] as? Int,
        let input = args["input"] as? String,
        let output = args["output"] as? String,
        let videoBitrate = args["videoBitrate"] as? Int,
        let audioBitrate = args["audioBitrate"] as? Int,
        let shortSide = args["shortSide"] as? Int,
        let frameRate = args["frameRate"] as? Int
      else {
        result(FlutterError(code: "bad_args", message: "Missing arguments", details: nil))
        return
      }
      let job = VideoCompression(
        input: URL(fileURLWithPath: input),
        output: URL(fileURLWithPath: output),
        settings: EncodeSettings(
          videoBitrate: videoBitrate, audioBitrate: audioBitrate, shortSide: shortSide,
          frameRate: frameRate, audioChannels: args["audioChannels"] as? Int ?? 2))
      jobs[id] = job
      job.start(
        progress: { [weak self] progress in
          DispatchQueue.main.async {
            self?.channel.invokeMethod("progress", arguments: ["id": id, "progress": progress])
          }
        },
        completion: { [weak self] error in
          DispatchQueue.main.async {
            self?.jobs[id] = nil
            result(error.map(Self.flutterError))
          }
        })
    case "cancel":
      if let id = call.arguments as? Int { jobs[id]?.cancel() }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func flutterError(_ error: Error) -> FlutterError {
    if case CompressionError.cancelled = error {
      return FlutterError(code: "cancelled", message: nil, details: nil)
    }
    return FlutterError(code: "failed", message: error.localizedDescription, details: nil)
  }
}

struct EncodeSettings {
  let videoBitrate: Int
  let audioBitrate: Int
  let shortSide: Int
  let frameRate: Int
  let audioChannels: Int
}

enum CompressionError: LocalizedError {
  case cancelled
  case noVideoTrack
  case failed(String)

  var errorDescription: String? {
    switch self {
    case .cancelled: return "Cancelled"
    case .noVideoTrack: return "No video track"
    case .failed(let message): return message
    }
  }
}

/// Re-encodes one video to H.264 and AAC in an MP4.
///
/// Frames go through a video composition, which applies the track's rotation,
/// scales to the output size, drops frames above the frame rate and converts
/// HDR to SDR (Rec. 709).
final class VideoCompression {
  private let input: URL
  private let output: URL
  private let settings: EncodeSettings
  private let lock = NSLock()
  private var cancelled = false
  private var reader: AVAssetReader?
  private var writer: AVAssetWriter?

  init(input: URL, output: URL, settings: EncodeSettings) {
    self.input = input
    self.output = output
    self.settings = settings
  }

  private var isCancelled: Bool {
    lock.lock()
    defer { lock.unlock() }
    return cancelled
  }

  static func probe(_ url: URL) async throws -> [String: Any] {
    let asset = AVURLAsset(url: url)
    let duration = try await asset.load(.duration)
    guard let video = try await asset.loadTracks(withMediaType: .video).first else {
      throw CompressionError.noVideoTrack
    }
    let (naturalSize, transform) = try await video.load(.naturalSize, .preferredTransform)
    let size = naturalSize.applying(transform)
    let hasAudio = !(try await asset.loadTracks(withMediaType: .audio)).isEmpty
    return [
      "durationMs": duration.seconds * 1000,
      "width": Int(abs(size.width).rounded()),
      "height": Int(abs(size.height).rounded()),
      "hasAudio": hasAudio,
    ]
  }

  func start(progress: @escaping (Double) -> Void, completion: @escaping (Error?) -> Void) {
    Task {
      do {
        try await run(progress: progress)
        completion(nil)
      } catch {
        reader?.cancelReading()
        writer?.cancelWriting()
        try? FileManager.default.removeItem(at: output)
        completion(isCancelled ? CompressionError.cancelled : error)
      }
    }
  }

  func cancel() {
    lock.lock()
    cancelled = true
    lock.unlock()
    reader?.cancelReading()
  }

  private func run(progress: @escaping (Double) -> Void) async throws {
    try? FileManager.default.removeItem(at: output)
    let asset = AVURLAsset(url: input)
    let duration = try await asset.load(.duration).seconds
    guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
      throw CompressionError.noVideoTrack
    }
    let audioTrack = try await asset.loadTracks(withMediaType: .audio).first
    let (naturalSize, transform, nominalFrameRate) = try await videoTrack.load(
      .naturalSize, .preferredTransform, .nominalFrameRate)

    let displaySize = naturalSize.applying(transform)
    let width = abs(displaySize.width)
    let height = abs(displaySize.height)
    let scale = min(1, CGFloat(settings.shortSide) / min(width, height))
    let renderSize = CGSize(width: Self.even(width * scale), height: Self.even(height * scale))
    let frameRate =
      nominalFrameRate > 0
      ? min(Float(settings.frameRate), nominalFrameRate) : Float(settings.frameRate)

    let reader = try AVAssetReader(asset: asset)
    let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
    self.reader = reader
    self.writer = writer
    writer.shouldOptimizeForNetworkUse = true

    let videoOutput = AVAssetReaderVideoCompositionOutput(
      videoTracks: [videoTrack],
      videoSettings: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      ])
    videoOutput.videoComposition = try await Self.composition(
      asset: asset, renderSize: renderSize, frameRate: frameRate)
    videoOutput.alwaysCopiesSampleData = false
    reader.add(videoOutput)

    let rec709: [String: Any] = [
      AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
      AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
      AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
    ]
    let videoInput = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: renderSize.width,
        AVVideoHeightKey: renderSize.height,
        AVVideoColorPropertiesKey: rec709,
        AVVideoCompressionPropertiesKey: [
          AVVideoAverageBitRateKey: settings.videoBitrate,
          AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
          AVVideoExpectedSourceFrameRateKey: frameRate,
          AVVideoMaxKeyFrameIntervalDurationKey: 2,
        ],
      ])
    videoInput.expectsMediaDataInRealTime = false
    writer.add(videoInput)

    var audio: (output: AVAssetReaderTrackOutput, input: AVAssetWriterInput)?
    if let audioTrack {
      let audioOutput = AVAssetReaderTrackOutput(
        track: audioTrack,
        outputSettings: [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVSampleRateKey: 44_100,
          AVNumberOfChannelsKey: settings.audioChannels,
        ])
      audioOutput.alwaysCopiesSampleData = false
      var audioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: 44_100,
        AVNumberOfChannelsKey: settings.audioChannels,
        AVEncoderBitRateKey: settings.audioBitrate,
      ]
      // Leave the bitrate to the encoder if it doesn't support this one.
      if !writer.canApply(outputSettings: audioSettings, forMediaType: .audio) {
        audioSettings.removeValue(forKey: AVEncoderBitRateKey)
      }
      let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
      audioInput.expectsMediaDataInRealTime = false
      if reader.canAdd(audioOutput) && writer.canAdd(audioInput) {
        reader.add(audioOutput)
        writer.add(audioInput)
        audio = (audioOutput, audioInput)
      }
    }

    guard reader.startReading() else {
      throw reader.error ?? CompressionError.failed("Couldn't read the video")
    }
    guard writer.startWriting() else {
      throw writer.error ?? CompressionError.failed("Couldn't write the video")
    }
    writer.startSession(atSourceTime: .zero)

    let reported = Box(-1)
    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        await self.copy(from: videoOutput, to: videoInput, label: "video") { sample in
          guard duration > 0 else { return }
          let time = CMSampleBufferGetPresentationTimeStamp(sample).seconds
          let step = Int(min(1, max(0, time / duration)) * 200)
          if step > reported.value {
            reported.value = step
            progress(Double(step) / 200)
          }
        }
      }
      if let audio {
        group.addTask {
          await self.copy(from: audio.output, to: audio.input, label: "audio") { _ in }
        }
      }
    }

    if isCancelled { throw CompressionError.cancelled }
    if reader.status == .failed {
      throw reader.error ?? CompressionError.failed("Couldn't read the video")
    }
    await writer.finishWriting()
    if writer.status != .completed {
      throw writer.error ?? CompressionError.failed("Couldn't write the video")
    }
    progress(1)
  }

  /// Appends samples from [output] to [input] until either runs out or the
  /// job is cancelled.
  private func copy(
    from output: AVAssetReaderOutput, to input: AVAssetWriterInput, label: String,
    onSample: @escaping (CMSampleBuffer) -> Void
  ) async {
    let queue = DispatchQueue(label: "blastqr_video.\(label)")
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let done = Box(false)
      input.requestMediaDataWhenReady(on: queue) {
        guard !done.value else { return }
        while input.isReadyForMoreMediaData {
          guard !self.isCancelled, let sample = output.copyNextSampleBuffer() else {
            done.value = true
            input.markAsFinished()
            continuation.resume()
            return
          }
          onSample(sample)
          if !input.append(sample) {
            done.value = true
            continuation.resume()
            return
          }
        }
      }
    }
  }

  private static func composition(asset: AVAsset, renderSize: CGSize, frameRate: Float)
    async throws -> AVMutableVideoComposition
  {
    let handler: (AVAsynchronousCIImageFilteringRequest) -> Void = { request in
      let source = request.sourceImage
      let extent = source.extent
      let image =
        source
        .transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
        .transformed(
          by: CGAffineTransform(
            scaleX: renderSize.width / extent.width, y: renderSize.height / extent.height))
        .cropped(to: CGRect(origin: .zero, size: renderSize))
      request.finish(with: image, context: nil)
    }
    let composition: AVMutableVideoComposition
    if #available(iOS 16.0, macOS 13.0, *) {
      composition = try await AVMutableVideoComposition.videoComposition(
        with: asset, applyingCIFiltersWithHandler: handler)
    } else {
      composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: handler)
    }
    composition.renderSize = renderSize
    // Frames otherwise follow the source track's timing, ignoring the
    // frame duration, so higher frame rates aren't dropped.
    composition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
    composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate.rounded()))
    composition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
    composition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
    composition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2
    return composition
  }

  /// Encoders want even dimensions.
  private static func even(_ value: CGFloat) -> CGFloat {
    max(2, CGFloat(Int((value / 2).rounded()) * 2))
  }
}

/// Mutable state for callbacks that each run on one serial queue.
private final class Box<Value> {
  var value: Value

  init(_ value: Value) {
    self.value = value
  }
}
