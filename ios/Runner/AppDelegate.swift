import Flutter
import UIKit
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if #available(iOS 26.0, *),
       let searchRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ChronoNativeSearch") {
      searchRegistrar.register(ChronoSearchFactory(messenger: searchRegistrar.messenger()), withId: "chrono/native_search")
    }
    if let switchRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "ChronoSettingsSwitch") {
      let messenger = switchRegistrar.messenger()
      switchRegistrar.register(SettingsSwitchFactory(messenger: messenger), withId: "chrono/settings_switch")
      FlutterMethodChannel(name: "chrono/settings_switch", binaryMessenger: messenger)
        .setMethodCallHandler { call, result in
          result(call.method == "isAvailable" ? true : FlutterMethodNotImplemented)
        }
    }
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HomeworkDatePicker") else { return }
    registrar.register(HomeworkContextMenuFactory(messenger: registrar.messenger()),
                       withId: "chrono/homework_context_menu")
    let channel = FlutterMethodChannel(name: "chrono/homework_date", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickDate", let args = call.arguments as? [String: String] else {
        result(FlutterMethodNotImplemented); return
      }
      guard let root = self?.window?.rootViewController ??
        UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
          .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
        result(FlutterError(code: "no_window", message: "Kalender nicht verfügbar", details: nil)); return
      }
      var presenter = root
      while let presented = presenter.presentedViewController { presenter = presented }
      let picker = HomeworkDatePickerController()
      picker.modalPresentationStyle = .formSheet
      picker.preferredContentSize = CGSize(width: 400, height: 480)
      picker.arguments = args
      picker.completion = result
      presenter.present(picker, animated: true)
    }
  }
}

private final class HomeworkDatePickerController: UIViewController {
  var arguments: [String: String] = [:]
  var completion: FlutterResult?
  private let picker = UIDatePicker()
  private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    isModalInPresentation = true
    picker.datePickerMode = .date
    picker.locale = Locale(identifier: "de_DE")
    picker.preferredDatePickerStyle = .inline
    picker.minimumDate = arguments["minimum"].flatMap(formatter.date(from:))
    picker.maximumDate = arguments["maximum"].flatMap(formatter.date(from:))
    picker.date = arguments["initial"].flatMap(formatter.date(from:)) ?? Date()
    let cancel = UIButton(type: .system)
    cancel.setTitle("Abbrechen", for: .normal)
    cancel.addTarget(self, action: #selector(cancelled), for: .touchUpInside)
    let done = UIButton(type: .system)
    done.setTitle("Fertig", for: .normal)
    done.addTarget(self, action: #selector(confirmed), for: .touchUpInside)
    let buttons = UIStackView(arrangedSubviews: [cancel, UIView(), done])
    let title = UILabel()
    title.text = "Abgabetag"
    title.font = .preferredFont(forTextStyle: .headline)
    title.textAlignment = .center
    done.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    let stack = UIStackView(arrangedSubviews: [buttons, title, picker])
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
    ])
    if let sheet = sheetPresentationController {
      if #available(iOS 16.0, *) {
        sheet.detents = [.custom(identifier: .init("homeworkCalendar")) { context in
          min(540, context.maximumDetentValue)
        }, .large()]
      } else {
        sheet.detents = [.large()]
      }
      sheet.prefersGrabberVisible = true
    }
  }
  @objc private func cancelled() { finish(nil) }
  @objc private func confirmed() { finish(formatter.string(from: picker.date)) }
  private func finish(_ value: String?) {
    dismiss(animated: true) { self.completion?(value); self.completion = nil }
  }
}


@available(iOS 26.0, *)
private final class ChronoSearchFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    ChronoSearchPlatformView(frame: frame, id: viewId, args: args, messenger: messenger)
  }
}

@available(iOS 26.0, *)
private final class ChronoSearchState: ObservableObject {
  @Published var text: String
  @Published var focused = false
  init(text: String) { self.text = text }
}

@available(iOS 26.0, *)
private final class ChronoSearchPlatformView: NSObject, FlutterPlatformView {
  private let host: UIHostingController<ChronoSearchField>
  private let channel: FlutterMethodChannel
  init(frame: CGRect, id: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    let params = args as? [String: Any] ?? [:]
    let state = ChronoSearchState(text: params["text"] as? String ?? "")
    let channel = FlutterMethodChannel(name: "chrono/native_search/\(id)", binaryMessenger: messenger)
    self.channel = channel
    host = UIHostingController(rootView: ChronoSearchField(state: state, channel: channel))
    super.init()
    host.view.frame = frame
    host.view.backgroundColor = .clear
    host.overrideUserInterfaceStyle = params["isDark"] as? Bool == true ? .dark : .light
    channel.setMethodCallHandler { call, result in
      if call.method == "unfocus" {
        state.focused = false
        result(nil)
      } else { result(FlutterMethodNotImplemented) }
    }
  }
  func view() -> UIView { host.view }
  deinit { channel.setMethodCallHandler(nil) }
}

@available(iOS 26.0, *)
private struct ChronoSearchField: View {
  @ObservedObject var state: ChronoSearchState
  let channel: FlutterMethodChannel
  @FocusState private var focused: Bool
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
      TextField("Suche nach Termin", text: $state.text)
        .font(.system(size: 17))
        .submitLabel(.search)
        .focused($focused)
        .onSubmit { focused = false }
      if !state.text.isEmpty {
        Button { state.text = "" } label: {
          Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
        }.accessibilityLabel("Suchtext löschen")
      }
      Button {
        focused = false
        channel.invokeMethod("filter", arguments: nil)
      } label: {
        Image(systemName: "line.3.horizontal.decrease").foregroundStyle(.secondary)
          .frame(width: 32, height: 44).contentShape(Rectangle())
      }.accessibilityLabel("Filter")
    }
    .buttonStyle(.plain)
    .padding(.leading, 12).padding(.trailing, 4)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .glassEffect(.regular.interactive(), in: .capsule)
    .onChange(of: state.text) { _, text in channel.invokeMethod("textChanged", arguments: text) }
    .onChange(of: focused) { _, value in
      state.focused = value
      channel.invokeMethod("focusChanged", arguments: value)
    }
    .onChange(of: state.focused) { _, value in focused = value }
  }
}


private final class HomeworkContextMenuFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    HomeworkContextMenuView(frame: frame, id: viewId, args: args as? [String: Any] ?? [:], messenger: messenger)
  }
}

private final class HomeworkContextMenuView: NSObject, FlutterPlatformView, UIContextMenuInteractionDelegate {
  private let content: UIView
  private let channel: FlutterMethodChannel
  private let completed: Bool
  private let flagged: Bool
  private let title: String

  init(frame: CGRect, id: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
    content = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "chrono/homework_context_menu/\(id)", binaryMessenger: messenger)
    completed = args["completed"] as? Bool ?? false
    flagged = args["flagged"] as? Bool ?? false
    title = args["title"] as? String ?? "Aufgabe"
    super.init()
    content.backgroundColor = .clear
    content.addInteraction(UIContextMenuInteraction(delegate: self))
    content.isAccessibilityElement = true
    content.accessibilityLabel = title
    content.accessibilityHint = "Gedrückt halten für Aufgabenaktionen"
    content.accessibilityCustomActions = [
      UIAccessibilityCustomAction(name: "Bearbeiten", actionHandler: { [weak self] _ in self?.send("edit"); return true }),
      UIAccessibilityCustomAction(name: completed ? "Als offen markieren" : "Als erledigt markieren", actionHandler: { [weak self] _ in self?.send("toggle"); return true }),
      UIAccessibilityCustomAction(name: flagged ? "Markierung entfernen" : "Markieren", actionHandler: { [weak self] _ in self?.send("flag"); return true }),
      UIAccessibilityCustomAction(name: "Löschen", actionHandler: { [weak self] _ in self?.send("delete"); return true })
    ]
    let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
    swipe.direction = .left
    content.addGestureRecognizer(swipe)
  }
  func view() -> UIView { content }
  private func send(_ action: String) { channel.invokeMethod("action", arguments: action) }
  @objc private func swiped() { send("delete") }

  func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
      configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      guard let self else { return nil }
      let edit = UIAction(title: "Bearbeiten", image: UIImage(systemName: "pencil")) { [weak self] _ in self?.send("edit") }
      let toggle = UIAction(title: self.completed ? "Als offen markieren" : "Als erledigt markieren",
                            image: UIImage(systemName: self.completed ? "circle" : "checkmark.circle")) { [weak self] _ in self?.send("toggle") }
      let flag = UIAction(title: self.flagged ? "Markierung entfernen" : "Markieren",
                          image: UIImage(systemName: self.flagged ? "flag.slash" : "flag")) { [weak self] _ in self?.send("flag") }
      let delete = UIAction(title: "Löschen", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in self?.send("delete") }
      return UIMenu(children: [edit, toggle, flag, UIMenu(options: .displayInline, children: [delete])])
    }
  }
}

private final class SettingsSwitchFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier id: Int64, arguments args: Any?) -> FlutterPlatformView {
    SettingsSwitchView(frame: frame, id: id, args: args, messenger: messenger)
  }
}

private final class SettingsSwitchView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let control = UISwitch()
  private let channel: FlutterMethodChannel

  init(frame: CGRect, id: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "chrono/settings_switch/\(id)", binaryMessenger: messenger)
    super.init()
    control.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(control)
    NSLayoutConstraint.activate([
      control.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      control.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])
    control.addTarget(self, action: #selector(changed), for: .valueChanged)
    update(args)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update" else { result(FlutterMethodNotImplemented); return }
      self?.update(call.arguments)
      result(nil)
    }
  }

  func view() -> UIView { container }

  private func update(_ arguments: Any?) {
    guard let args = arguments as? [String: Any] else { return }
    control.setOn(args["value"] as? Bool ?? false, animated: false)
    control.isEnabled = args["enabled"] as? Bool ?? false
    control.accessibilityLabel = args["label"] as? String
    container.overrideUserInterfaceStyle = args["isDark"] as? Bool == true ? .dark : .light
  }

  @objc private func changed() {
    channel.invokeMethod("changed", arguments: control.isOn)
  }

  deinit { channel.setMethodCallHandler(nil) }
}
