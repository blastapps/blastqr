import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

/// Hands files opened from Finder's "Open With" to Dart, holding them until
/// Dart asks for them on launch.
class OpenedFiles: NSObject, FlutterAppLifecycleDelegate {
  private let channel: FlutterMethodChannel
  private var pending: [String]? = []

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "blastqr/open_files", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "ready", let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self.pending ?? [])
      self.pending = nil
    }
  }

  func handleOpen(_ urls: [URL]) -> Bool {
    let paths = urls.filter(\.isFileURL).map(\.path)
    if paths.isEmpty { return false }
    if pending != nil {
      pending! += paths
    } else {
      channel.invokeMethod("open", arguments: paths)
    }
    return true
  }
}
