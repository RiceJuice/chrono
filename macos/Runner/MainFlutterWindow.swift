import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private weak var homeworkUndoToast: HomeworkUndoToast?

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

    FlutterMethodChannel(
      name: "chrono/homework_undo",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
      .setMethodCallHandler { [weak self] call, result in
        guard call.method == "show",
              let args = call.arguments as? [String: String],
              let message = args["message"], let action = args["action"] else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let self, let host = self.contentView else {
          result(FlutterError(code: "no_window", message: nil, details: nil))
          return
        }
        self.homeworkUndoToast?.finish(false)
        let toast = HomeworkUndoToast(message: message, action: action, result: result)
        self.homeworkUndoToast = toast
        host.addSubview(toast)
        NSLayoutConstraint.activate([
          toast.centerXAnchor.constraint(equalTo: host.centerXAnchor),
          toast.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor, constant: 16),
          toast.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor, constant: -16),
          toast.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -72),
        ])
        NSAccessibility.post(
          element: toast,
          notification: .announcementRequested,
          userInfo: [.announcement: "\(message). \(action).", .priority: NSAccessibilityPriorityLevel.medium.rawValue]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak toast] in toast?.finish(false) }
      }

    super.awakeFromNib()
  }
}

private final class HomeworkUndoToast: NSVisualEffectView {
  private var result: FlutterResult?

  init(message: String, action: String, result: @escaping FlutterResult) {
    self.result = result
    super.init(frame: .zero)
    material = .popover
    blendingMode = .withinWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 12
    layer?.masksToBounds = true
    translatesAutoresizingMaskIntoConstraints = false

    let label = NSTextField(labelWithString: message)
    let button = NSButton(title: action, target: self, action: #selector(undo))
    button.bezelStyle = .rounded
    button.controlSize = .small

    let stack = NSStackView(views: [label, button])
    stack.alignment = .centerY
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

  @objc private func undo() { finish(true) }

  func finish(_ tapped: Bool) {
    let completion = result
    result = nil
    removeFromSuperview()
    completion?(tapped)
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
