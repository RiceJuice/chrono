import SwiftUI

#if os(iOS)
import Flutter
import UIKit
typealias MusicLessonEditorWindow = UIWindow
#elseif os(macOS)
import FlutterMacOS
import AppKit
typealias MusicLessonEditorWindow = NSWindow
#endif

@available(iOS 16.0, macOS 13.0, *)
final class MusicLessonEditorChannel {
  private let channel: FlutterMethodChannel
  private let window: () -> MusicLessonEditorWindow?
  private var presenting = false

  init(messenger: FlutterBinaryMessenger, window: @escaping () -> MusicLessonEditorWindow?) {
    self.channel = FlutterMethodChannel(name: "chrono/music_lesson_editor", binaryMessenger: messenger)
    self.window = window
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "present", let options = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self, !self.presenting, let window = self.window() else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      self.present(options, in: window, result: result)
    }
  }

  private func present(
    _ options: [String: Any], in window: MusicLessonEditorWindow, result: @escaping FlutterResult
  ) {
    #if os(iOS)
    guard var presenter = window.rootViewController else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    guard presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    #elseif os(macOS)
    guard window.attachedSheet == nil else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    #endif

    presenting = true
    let finish: ([String: Any]?) -> Void = { [weak self] value in
      self?.presenting = false
      result(value)
    }
    let model = MusicLessonEditorModel(options: options)
    let content = MusicLessonEditor(model: model)
      .environment(\.locale, Locale(identifier: "de_DE"))
      .environment(\.timeZone, MusicLessonEditorModel.timeZone)

    #if os(iOS)
    let sheet = UIHostingController(rootView: content)
    sheet.modalPresentationStyle = .formSheet
    sheet.preferredContentSize = CGSize(width: 480, height: 580)
    sheet.isModalInPresentation = true
    model.close = { [weak sheet] value in
      sheet?.dismiss(animated: true) { finish(value) }
    }
    presenter.present(sheet, animated: true)
    #elseif os(macOS)
    let sheet = NSWindow(contentViewController: NSHostingController(rootView: content))
    sheet.styleMask = [.titled]
    sheet.title = model.title
    sheet.setContentSize(NSSize(width: 480, height: 520))
    model.close = { [weak window, weak sheet] value in
      model.result = value
      if let sheet { window?.endSheet(sheet) }
    }
    window.beginSheet(sheet) { _ in
      model.close = nil
      finish(model.result)
    }
    #endif
  }
}

@available(iOS 16.0, macOS 13.0, *)
private final class MusicLessonEditorModel: ObservableObject {
  static let timeZone = TimeZone(secondsFromGMT: 0)!
  let title: String
  let extendedLabel: String
  let standardMinutes: Int
  let hasInstrument: Bool
  let hasSavedLesson: Bool
  let instruments: [String]

  @Published var weekday: Int
  @Published var date: Date
  @Published var instrument: String
  @Published var teacher: String
  @Published var extended: Bool
  var close: (([String: Any]?) -> Void)?
  var result: [String: Any]?

  init(options: [String: Any]) {
    title = options["title"] as? String ?? "Musikunterricht"
    extendedLabel = options["extendedLabel"] as? String ?? "45 Min."
    standardMinutes = options["standardMinutes"] as? Int ?? 25
    hasInstrument = options["hasInstrument"] as? Bool ?? false
    instruments = options["instruments"] as? [String] ?? []
    weekday = options["weekday"] as? Int ?? 0
    let startMinute = options["startMinute"] as? Int
    hasSavedLesson = startMinute != nil
    date = Date(timeIntervalSince1970: Double((startMinute ?? 840) * 60))
    instrument = options["instrument"] as? String ?? ""
    teacher = options["teacher"] as? String ?? ""
    extended = options["extended"] as? Bool ?? false
  }

  private var minute: Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = Self.timeZone
    return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
  }

  private var instrumentName: String { instrument.trimmingCharacters(in: .whitespacesAndNewlines) }
  private var teacherName: String { teacher.trimmingCharacters(in: .whitespacesAndNewlines) }
  var duration: Int { extended ? 45 : standardMinutes }
  var endsTooLate: Bool { minute + duration > 1440 }
  var canSave: Bool {
    (1...5).contains(weekday) && !endsTooLate && (!hasInstrument || !instrumentName.isEmpty)
  }

  var suggestions: [String] {
    let prefix = instrumentName.lowercased()
    guard !prefix.isEmpty else { return [] }
    return Array(instruments.filter {
      $0.lowercased().hasPrefix(prefix) && $0.lowercased() != prefix
    }.prefix(4))
  }

  func accept() {
    guard canSave else { return }
    var value: [String: Any] = ["weekday": weekday, "startMinute": minute, "extended": extended]
    if hasInstrument { value["instrument"] = instrumentName }
    if !teacherName.isEmpty { value["teacher"] = teacherName }
    close?(value)
  }
}

@available(iOS 16.0, macOS 13.0, *)
private struct MusicLessonEditor: View {
  @ObservedObject var model: MusicLessonEditorModel
  @FocusState private var instrumentFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      Text(model.title)
        .font(.headline)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityAddTraits(.isHeader)
      Form {
        Section {
          Picker("Wochentag", selection: $model.weekday) {
            Text("Mo").accessibilityLabel("Montag").tag(1)
            Text("Di").accessibilityLabel("Dienstag").tag(2)
            Text("Mi").accessibilityLabel("Mittwoch").tag(3)
            Text("Do").accessibilityLabel("Donnerstag").tag(4)
            Text("Fr").accessibilityLabel("Freitag").tag(5)
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .accessibilityLabel("Wochentag")

          DatePicker("Beginn", selection: $model.date, displayedComponents: .hourAndMinute)
            #if os(iOS)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityLabel("Beginn")
            .frame(maxWidth: .infinity)
            #elseif os(macOS)
            .datePickerStyle(.compact)
            #endif
          if model.endsTooLate {
            Text("Der Termin muss am selben Tag enden.")
              .font(.footnote)
              .foregroundStyle(.red)
          }
        } header: {
          Text("Wochentag und Uhrzeit")
        }

        Section {
          if model.hasInstrument {
            TextField("Instrument, z. B. Klavier", text: $model.instrument)
              .focused($instrumentFocused)
              .onChange(of: model.instrument) { value in
                if value.count > 80 { model.instrument = String(value.prefix(80)) }
              }
            if instrumentFocused {
              ForEach(model.suggestions, id: \.self) { name in
                Button(name) {
                  model.instrument = name
                  instrumentFocused = false
                }
              }
            }
          }
          TextField("Lehrkraft (optional)", text: $model.teacher)
            .onChange(of: model.teacher) { value in
              if value.count > 100 { model.teacher = String(value.prefix(100)) }
            }
          Toggle(model.extendedLabel, isOn: $model.extended)
            .toggleStyle(.switch)
        } header: {
          Text("Unterricht")
        } footer: {
          Text("\(model.duration) Min. pro Woche")
        }

        if model.hasSavedLesson {
          Section {
            Button("Termin entfernen", role: .destructive) { model.close?(["remove": true]) }
          }
        }
      }
      .formStyle(.grouped)
      Divider()
      if #available(iOS 26.0, macOS 26.0, *) {
        actions
          .buttonStyle(.glass)
          .buttonBorderShape(.circle)
          .controlSize(.large)
      } else {
        actions
          .buttonStyle(.bordered)
          .controlSize(.large)
      }
    }
  }

  private var actions: some View {
    HStack {
      Button(role: .cancel) { model.close?(nil) } label: {
        Image(systemName: "xmark")
      }
      .accessibilityLabel("Abbrechen")
      .keyboardShortcut(.cancelAction)
      Spacer()
      Button { model.accept() } label: {
        Image(systemName: "checkmark")
      }
      .accessibilityLabel("Übernehmen")
      .keyboardShortcut(.defaultAction)
      .disabled(!model.canSave)
    }
    .padding(16)
  }
}
