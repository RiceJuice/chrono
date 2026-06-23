import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.domspatzen.chronoapp"

private func imageKey(for family: WidgetFamily, isDark: Bool) -> String {
  let size = family == .systemLarge ? "large" : "medium"
  let theme = isDark ? "dark" : "light"
  return "calendar_widget_\(size)_\(theme)"
}

private func loadWidgetImage(for family: WidgetFamily, isDark: Bool) -> UIImage? {
  let path = UserDefaults(suiteName: widgetGroupId)?.string(forKey: imageKey(for: family, isDark: isDark))
  guard let path, !path.isEmpty else { return nil }
  return UIImage(contentsOfFile: path)
}

struct CalendarHomeWidgetEntry: TimelineEntry {
  let date: Date
  let family: WidgetFamily
}

struct CalendarHomeWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> CalendarHomeWidgetEntry {
    CalendarHomeWidgetEntry(date: Date(), family: context.family)
  }

  func getSnapshot(in context: Context, completion: @escaping (CalendarHomeWidgetEntry) -> Void) {
    completion(CalendarHomeWidgetEntry(date: Date(), family: context.family))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarHomeWidgetEntry>) -> Void) {
    let entry = CalendarHomeWidgetEntry(date: Date(), family: context.family)
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
  }
}

struct ChronoCalendarHomeWidgetEntryView: View {
  @Environment(\.colorScheme) private var colorScheme
  var entry: CalendarHomeWidgetProvider.Entry

  var body: some View {
    Group {
      if let image = loadWidgetImage(for: entry.family, isDark: colorScheme == .dark) {
        Image(uiImage: image)
          .resizable()
          .interpolation(.high)
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      } else {
        ZStack {
          Color(.systemBackground)
          Text("Chrono")
            .font(.headline)
            .foregroundStyle(.secondary)
        }
      }
    }
    .widgetURL(URL(string: "chronoapp://calendar"))
  }
}

struct ChronoCalendarHomeWidget: Widget {
  let kind: String = "ChronoCalendarHomeWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CalendarHomeWidgetProvider()) { entry in
      ChronoCalendarHomeWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Termine")
    .description("Deine nächsten Termine im Kalender-Look.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
