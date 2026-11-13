import AVFoundation
import Flutter
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // The camera plugin sets PlayAndRecord without defaultToSpeaker, silently
    // routing SoLoud output to the earpiece. Override to use the speaker.
    try? AVAudioSession.sharedInstance().setCategory(
      .playAndRecord,
      options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth]
    )
    try? AVAudioSession.sharedInstance().setActive(true)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Blastqr") else {
      return
    }
    FlutterMethodChannel(name: "blastqr/camera", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "configureScanCamera":
          Self.configureScanCamera(
            videoHdr: args["videoHdr"] as? Bool ?? false,
            maxExposureMs: args["maxExposureMs"] as? Double,
            exposureMs: args["exposureMs"] as? Double)
          result(nil)
        case "supportedFrameRates":
          result(
            Self.supportedFrameRates(
              width: args["width"] as? Int ?? 0, height: args["height"] as? Int ?? 0))
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    FlutterMethodChannel(name: "blastqr/debug", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        switch call.method {
        case "deviceModel": result(Self.deviceModel())
        case "cameraState": result(Self.cameraState())
        default: result(FlutterMethodNotImplemented)
        }
      }
    FlutterMethodChannel(name: "blastqr/device", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        switch call.method {
        // How much more memory this app can use before iOS closes it.
        case "availableMemory": result(Int(os_proc_available_memory()))
        default: result(FlutterMethodNotImplemented)
        }
      }
    FlutterMethodChannel(name: "blastqr/files", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        switch call.method {
        case "sharedContainerPath":
          let group = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String ?? ""
          result(
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.path)
        case "excludeFromBackup":
          guard let path = call.arguments as? String else {
            result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
            return
          }
          var url = URL(fileURLWithPath: path, isDirectory: true)
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          do {
            try url.setResourceValues(values)
            result(nil)
          } catch {
            result(
              FlutterError(code: "failed", message: error.localizedDescription, details: nil))
          }
        case "saveToFiles":
          guard let paths = call.arguments as? [String] else {
            result(FlutterError(code: "bad_args", message: "Missing paths", details: nil))
            return
          }
          Self.saveToFiles(paths.map { URL(fileURLWithPath: $0) }, result: result)
        default: result(FlutterMethodNotImplemented)
        }
      }
  }

  // The picker holds its delegate weakly.
  private static var exportDelegate: ExportDelegate?

  /// Lets the user pick a folder to copy the files into. Returns how many were saved, 0 if cancelled.
  private static func saveToFiles(_ urls: [URL], result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_view", message: "No view to present from", details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
    let delegate = ExportDelegate { saved in
      exportDelegate = nil
      result(saved)
    }
    exportDelegate = delegate
    picker.delegate = delegate
    presenter.present(picker, animated: true)
  }

  private static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }

  // Live state of the back wide camera, the one the scanner opens. Reading it
  // doesn't touch the capture session.
  private static func cameraState() -> [String: Any]? {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    else { return nil }
    let format = device.activeFormat
    let size = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    var state: [String: Any] = [
      "exposureMs": device.exposureDuration.seconds * 1000,
      "exposureLimitMs": device.activeMaxExposureDuration.seconds * 1000,
      "iso": Double(device.iso),
      "exposureBias": Double(device.exposureTargetBias),
      "exposureMode": device.exposureMode.name,
      "focusMode": device.focusMode.name,
      "lensPosition": Double(device.lensPosition),
      "zoom": Double(device.videoZoomFactor),
      "videoHDR": format.isVideoHDRSupported ? device.isVideoHDREnabled : false,
      "videoHDRSupported": format.isVideoHDRSupported,
      "adjustingFocus": device.isAdjustingFocus,
      "format": "\(size.width)x\(size.height)",
      "minFps": 1 / device.activeVideoMaxFrameDuration.seconds,
      "maxFps": 1 / device.activeVideoMinFrameDuration.seconds,
    ]
    if #available(iOS 15.0, *) {
      state["minFocusDistanceMm"] = device.minimumFocusDistance
    }
    return state
  }

  // Common frame rates that some format of the back wide camera supports at
  // this size, which is what the camera plugin picks from. A size of 0 means
  // the largest format, as the plugin's "max" preset uses.
  private static func supportedFrameRates(width: Int, height: Int) -> [Int] {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    else { return [] }
    func size(_ format: AVCaptureDevice.Format) -> CMVideoDimensions {
      CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    }
    var target = CMVideoDimensions(width: Int32(width), height: Int32(height))
    if width == 0 || height == 0 {
      guard
        let largest = device.formats.max(by: {
          Int(size($0).width) * Int(size($0).height) < Int(size($1).width) * Int(size($1).height)
        })
      else { return [] }
      target = size(largest)
    }
    let ranges = device.formats
      .filter { size($0).width == target.width && size($0).height == target.height }
      .flatMap { $0.videoSupportedFrameRateRanges }
    return [15, 24, 25, 30, 48, 50, 60, 120, 240].filter { fps in
      ranges.contains { Double(fps) >= $0.minFrameRate && Double(fps) <= $0.maxFrameRate }
    }
  }

  // ISO * exposure seconds that automatic exposure settled on, before we took
  // over. Re-reading it once exposure is custom would compound the ISO boost,
  // since the camera can still report the old exposure for a few frames.
  private static var autoBrightness: Double?

  // Settings the camera plugin doesn't offer, applied to the camera it has
  // already set up. Long exposures and video HDR blend two QR codes into one
  // frame whenever the sender changes code mid-capture.
  // - maxExposureMs caps automatic exposure; nil leaves it uncapped.
  // - exposureMs fixes the exposure instead (testing only), raising ISO to keep
  //   the image as bright as automatic exposure had it.
  // The format resets the cap, so this runs again whenever the camera restarts.
  private static func configureScanCamera(
    videoHdr: Bool, maxExposureMs: Double?, exposureMs: Double?
  ) {
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      (try? device.lockForConfiguration()) != nil
    else { return }
    defer { device.unlockForConfiguration() }

    let format = device.activeFormat
    if format.isVideoHDRSupported {
      device.automaticallyAdjustsVideoHDREnabled = videoHdr
      if !videoHdr { device.isVideoHDREnabled = false }
    }

    func clamped(_ ms: Double) -> CMTime {
      let seconds = min(
        max(ms / 1000, format.minExposureDuration.seconds), format.maxExposureDuration.seconds)
      return CMTime(seconds: seconds, preferredTimescale: 1_000_000)
    }

    guard let exposureMs else {
      if device.exposureMode == .custom,
        device.isExposureModeSupported(.continuousAutoExposure)
      {
        device.exposureMode = .continuousAutoExposure
      }
      device.activeMaxExposureDuration = maxExposureMs.map(clamped) ?? .invalid
      return
    }
    if device.exposureMode != .custom || autoBrightness == nil {
      autoBrightness = Double(device.iso) * device.exposureDuration.seconds
    }
    let target = clamped(exposureMs)
    let iso = min(
      max(Float(autoBrightness! / target.seconds), format.minISO), format.maxISO)
    device.setExposureModeCustom(duration: target, iso: iso)
  }

  // The hardware identifier, such as "iPhone16,1".
  private static func deviceModel() -> String {
    var info = utsname()
    uname(&info)
    return withUnsafeBytes(of: &info.machine) { bytes in
      String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
  }
}

extension AVCaptureDevice.ExposureMode {
  fileprivate var name: String {
    switch self {
    case .locked: return "locked"
    case .autoExpose: return "auto"
    case .continuousAutoExposure: return "continuous"
    case .custom: return "custom"
    @unknown default: return "unknown"
    }
  }
}

extension AVCaptureDevice.FocusMode {
  fileprivate var name: String {
    switch self {
    case .locked: return "locked"
    case .autoFocus: return "auto"
    case .continuousAutoFocus: return "continuous"
    @unknown default: return "unknown"
    }
  }
}

private final class ExportDelegate: NSObject, UIDocumentPickerDelegate {
  private let completion: (Int) -> Void

  init(completion: @escaping (Int) -> Void) {
    self.completion = completion
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    completion(urls.count)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion(0)
  }
}
