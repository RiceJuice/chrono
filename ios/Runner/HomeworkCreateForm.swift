import SwiftUI

#if os(iOS)
import Flutter
import UIKit
typealias HomeworkCreateWindow = UIWindow
#elseif os(macOS)
import FlutterMacOS
import AppKit
typealias HomeworkCreateWindow = NSWindow
#endif

@available(iOS 15.0, macOS 11.0, *)
final class HomeworkCreateChannel {
  private let channel: FlutterMethodChannel
  private let window: () -> HomeworkCreateWindow?
  private var form: HomeworkCreateModel?

  init(messenger: FlutterBinaryMessenger, window: @escaping () -> HomeworkCreateWindow?) {
    self.channel = FlutterMethodChannel(name: "chrono/homework_create", binaryMessenger: messenger)
    self.window = window
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let options = call.arguments as? [String: Any] else {
      result(FlutterMethodNotImplemented)
      return
    }
    switch call.method {
    case "update":
      form?.update(options)
      result(nil)
    case "present":
      guard form == nil, let window = window() else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      let form = HomeworkCreateModel(options: options, channel: channel)
      self.form = form
      present(form, in: window) { [weak self] in
        self?.form = nil
        result(nil)
      } unavailable: { [weak self] in
        self?.form = nil
        result(FlutterError(code: "unavailable", message: nil, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func present(
    _ form: HomeworkCreateModel,
    in window: HomeworkCreateWindow,
    completed: @escaping () -> Void,
    unavailable: () -> Void
  ) {
    let content = HomeworkCreateForm(model: form)
      .environment(\.locale, Locale(identifier: "de_DE"))
    #if os(iOS)
    guard var presenter = window.rootViewController else {
      unavailable()
      return
    }
    while let presented = presenter.presentedViewController {
      presenter = presented
    }
    guard presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else {
      unavailable()
      return
    }
    let sheet = UIHostingController(rootView: content)
    sheet.modalPresentationStyle = .formSheet
    sheet.preferredContentSize = CGSize(width: 540, height: 610)
    // The explicit cancel action protects the draft and keeps saves atomic.
    sheet.isModalInPresentation = true
    form.close = { [weak sheet] in
      sheet?.dismiss(animated: true, completion: completed)
    }
    presenter.present(sheet, animated: true)
    #elseif os(macOS)
    guard window.attachedSheet == nil else {
      unavailable()
      return
    }
    let sheet = NSWindow(contentViewController: NSHostingController(rootView: content))
    sheet.styleMask = [.titled]
    sheet.title = "Neue Aufgabe"
    sheet.setContentSize(NSSize(width: 520, height: 480))
    form.close = { [weak window, weak sheet] in
      if let sheet { window?.endSheet(sheet) }
    }
    window.beginSheet(sheet) { _ in completed() }
    #endif
  }
}

@available(iOS 15.0, macOS 11.0, *)
private final class HomeworkCreateModel: ObservableObject {
  struct Subject: Identifiable {
    let id: String
    let name: String
    let nextLesson: String?
  }

  enum Due: Hashable {
    case unset
    case nextLesson
    case customDate
  }

  @Published var title = ""
  @Published var notes = ""
  @Published private(set) var subjectId = ""
  @Published var due = Due.unset
  @Published var day: Date
  @Published private(set) var subjects: [Subject] = []
  @Published private(set) var subjectsLoading = false
  @Published private(set) var subjectsFailed = false
  @Published private(set) var lessonsLoading = false
  @Published private(set) var lessonsFailed = false
  @Published private(set) var saving = false
  @Published var error: String?
  var close: () -> Void = {}
  let allowedDays: ClosedRange<Date>

  private let channel: FlutterMethodChannel
  private var choseSubjectOrDate = false

  init(options: [String: Any], channel: FlutterMethodChannel) {
    self.channel = channel
    let calendar = Calendar(identifier: .gregorian)
    let today = calendar.startOfDay(for: Date())
    let year = calendar.component(.year, from: today)
    let lastDay = calendar.date(from: DateComponents(year: year + 5, month: 12, day: 31)) ?? today
    day = today
    allowedDays = today...lastDay
    update(options)
  }

  var nextLesson: String? {
    subjects.first(where: { $0.id == subjectId })?.nextLesson
  }

  var canSave: Bool {
    !saving && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
      (due == .customDate || (due == .nextLesson && nextLesson != nil))
  }

  func update(_ options: [String: Any]) {
    subjectsLoading = options["subjectsLoading"] as? Bool ?? false
    subjectsFailed = options["subjectsFailed"] as? Bool ?? false
    lessonsLoading = options["lessonsLoading"] as? Bool ?? false
    lessonsFailed = options["lessonsFailed"] as? Bool ?? false
    subjects = (options["subjects"] as? [[String: Any]] ?? []).compactMap { value in
      guard let id = value["id"] as? String, let name = value["name"] as? String else {
        return nil
      }
      return Subject(id: id, name: name, nextLesson: value["nextLesson"] as? String)
    }

    if !choseSubjectOrDate, subjectId.isEmpty,
       let current = options["currentSubjectId"] as? String,
       subjects.contains(where: { $0.id == current }) {
      subjectId = current
      due = .nextLesson
    } else if !subjectId.isEmpty, !subjectsLoading, !subjectsFailed,
              !subjects.contains(where: { $0.id == subjectId }) {
      selectSubject("")
    }
  }

  func selectSubject(_ id: String) {
    choseSubjectOrDate = true
    subjectId = id
    if id.isEmpty, due == .nextLesson {
      due = .unset
    } else if !id.isEmpty, due == .unset {
      due = .nextLesson
    }
  }

  func selectDue(_ value: Due) {
    choseSubjectOrDate = true
    due = value
  }

  func save() {
    guard canSave else { return }
    saving = true
    var draft: [String: Any] = ["title": title, "notes": notes, "nextLesson": due == .nextLesson]
    if !subjectId.isEmpty { draft["subjectId"] = subjectId }
    if due == .customDate {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.dateFormat = "yyyy-MM-dd"
      draft["day"] = formatter.string(from: day)
    }
    channel.invokeMethod("save", arguments: draft) { [weak self] response in
      guard let self else { return }
      if response == nil {
        self.close()
      } else {
        self.saving = false
        self.error = response as? String ?? "Aufgabe konnte nicht gespeichert werden."
      }
    }
  }
}

@available(iOS 15.0, macOS 11.0, *)
private struct HomeworkCreateForm: View {
  @ObservedObject var model: HomeworkCreateModel

  var body: some View {
    presentation
      .alert(isPresented: Binding(
        get: { model.error != nil },
        set: { if !$0 { model.error = nil } }
      )) {
        Alert(
          title: Text("Speichern fehlgeschlagen"),
          message: Text(model.error ?? ""),
          dismissButton: .default(Text("OK"))
        )
      }
  }

  @ViewBuilder
  private var presentation: some View {
    #if os(iOS)
    NavigationView {
      form
        .navigationTitle("Neue Aufgabe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { cancelButton }
          ToolbarItem(placement: .confirmationAction) { saveButton }
        }
    }
    .navigationViewStyle(.stack)
    #elseif os(macOS)
    VStack(spacing: 0) {
      if #available(macOS 13.0, *) {
        form.formStyle(.grouped)
      } else {
        ScrollView { form.padding(20) }
      }
      Divider()
      HStack {
        Spacer()
        cancelButton.keyboardShortcut(.cancelAction)
        saveButton.keyboardShortcut(.defaultAction)
      }
      .padding()
    }
    .frame(minWidth: 460, minHeight: 420)
    #endif
  }

  private var form: some View {
    Form {
      Section(header: Text("Aufgabe")) {
        #if os(iOS)
        titleField
          .textInputAutocapitalization(.sentences)
        #else
        titleField
        #endif
        VStack(alignment: .leading, spacing: 4) {
          Text("Notizen")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .accessibilityHidden(true)
          TextEditor(text: $model.notes)
            .font(.body)
            .frame(minHeight: 64, maxHeight: 100)
            .accessibilityLabel("Notizen, optional")
        }
      }
      Section(header: Text("Fach und Fälligkeit")) {
        Picker(selection: Binding(get: { model.subjectId }, set: model.selectSubject)) {
          Text("Kein Fach").tag("")
          ForEach(model.subjects) { subject in
            Text(subject.name).tag(subject.id)
          }
        } label: {
          Label("Fach", systemImage: "book")
        }
        .pickerStyle(.menu)

        if model.subjectsLoading && model.subjects.isEmpty {
          ProgressView("Fächer werden geladen …").font(.footnote)
        } else if model.subjectsFailed && model.subjects.isEmpty {
          Text("Fächer konnten nicht geladen werden. Du kannst ein eigenes Datum wählen.")
            .font(.footnote)
            .foregroundColor(.secondary)
        }

        Picker(selection: Binding(get: { model.due }, set: model.selectDue)) {
          if model.due == .unset { Text("Auswählen").tag(HomeworkCreateModel.Due.unset) }
          if !model.subjectId.isEmpty {
            Text("Nächste Stunde").tag(HomeworkCreateModel.Due.nextLesson)
          }
          Text("Eigenes Datum").tag(HomeworkCreateModel.Due.customDate)
        } label: {
          Label("Fällig am", systemImage: "calendar")
        }
        .pickerStyle(.menu)

        if model.due == .customDate {
          DatePicker("Abgabetag", selection: $model.day, in: model.allowedDays, displayedComponents: .date)
        } else if model.due == .nextLesson {
          if model.lessonsLoading {
            ProgressView("Stunde wird gesucht …").font(.footnote)
          } else {
            Text(model.nextLesson ?? (model.lessonsFailed
              ? "Kalender konnte nicht geladen werden."
              : "Keine kommende Stunde. Wähle ein eigenes Datum."))
              .font(.footnote)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .disabled(model.saving)
  }

  private var titleField: some View {
    TextField("Titel", text: $model.title)
      .font(.body.weight(.semibold))
      .accessibilityLabel("Titel")
  }

  private var cancelButton: some View {
    Button("Abbrechen", action: model.close)
      .disabled(model.saving)
  }

  private var saveButton: some View {
    Button(action: model.save) {
      if model.saving {
        ProgressView().controlSize(.small).accessibilityLabel("Wird gespeichert")
      } else {
        Text("Hinzufügen").fontWeight(.semibold)
      }
    }
    .disabled(!model.canSave)
  }
}
