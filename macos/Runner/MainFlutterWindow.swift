import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.minSize = NSSize(width: 960, height: 600)
    if self.frame.width < 960 || self.frame.height < 600 {
      self.setContentSize(NSSize(width: 1280, height: 800))
    }

    super.awakeFromNib()
  }
}
