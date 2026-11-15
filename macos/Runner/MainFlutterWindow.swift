import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var openedFiles: OpenedFiles?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.contentMinSize = NSSize(width: 300, height: 300)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let openedFiles = OpenedFiles(messenger: flutterViewController.engine.binaryMessenger)
    (NSApp.delegate as? FlutterAppDelegate)?.addApplicationLifecycleDelegate(openedFiles)
    self.openedFiles = openedFiles

    FlutterMethodChannel(
      name: "blastqr/files", binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { call, result in
      switch call.method {
      case "revealInFinder":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
          return
        }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
