import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let registrar = flutterViewController.registrar(forPlugin: "ChronoSettingsSwitch")
    let messenger = registrar.messenger
    registrar.register(SettingsSwitchFactory(messenger: messenger), withId: "chrono/settings_switch")
    FlutterMethodChannel(name: "chrono/settings_switch", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        result(call.method == "isAvailable" ? true : FlutterMethodNotImplemented)
      }

    super.awakeFromNib()
  }
}

private final class SettingsSwitchFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier id: Int64, arguments args: Any?) -> NSView {
    SettingsSwitchView(id: id, args: args, messenger: messenger)
  }
}

private final class SettingsSwitchView: NSView {
  private let control = NSSwitch()
  private let channel: FlutterMethodChannel

  init(id: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "chrono/settings_switch/\(id)", binaryMessenger: messenger)
    super.init(frame: .zero)
    control.translatesAutoresizingMaskIntoConstraints = false
    addSubview(control)
    NSLayoutConstraint.activate([
      control.centerXAnchor.constraint(equalTo: centerXAnchor),
      control.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
    control.target = self
    control.action = #selector(changed)
    update(args)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else { result(FlutterMethodNotImplemented); return }
      self?.update(call.arguments)
      result(nil)
    }
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

  private func update(_ arguments: Any?) {
    guard let args = arguments as? [String: Any] else { return }
    control.state = args["value"] as? Bool == true ? .on : .off
    control.isEnabled = args["enabled"] as? Bool ?? false
    control.setAccessibilityLabel(args["label"] as? String)
    appearance = NSAppearance(named: args["isDark"] as? Bool == true ? .darkAqua : .aqua)
  }

  @objc private func changed() {
    channel.invokeMethod("changed", arguments: control.state == .on)
  }

  deinit { channel.setMethodCallHandler(nil) }
}
