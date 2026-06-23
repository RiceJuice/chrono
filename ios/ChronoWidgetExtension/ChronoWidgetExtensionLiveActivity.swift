import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ChronoWidgetExtensionBundle: WidgetBundle {
  var body: some Widget {
    ChronoCalendarHomeWidget()
    if #available(iOS 16.1, *) {
      ChronoScheduleLiveActivity()
    }
  }
}

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  public struct ContentState: Codable, Hashable {}
  var id = UUID()
}

let sharedDefault = UserDefaults(suiteName: "group.com.domspatzen.chronoapp")!

private struct ScheduleLiveData {
  let eventId: String
  let currentTitle: String
  let currentSubtitle: String
  let hasNext: Bool
  let nextTitle: String
  let nextSubtitle: String
  let segmentStart: Date
  let segmentEnd: Date

  init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
    func key(_ name: String) -> String {
      context.attributes.prefixedKey(name)
    }
    currentTitle = sharedDefault.string(forKey: key("currentTitle")) ?? ""
    currentSubtitle = sharedDefault.string(forKey: key("currentSubtitle")) ?? ""
    eventId = sharedDefault.string(forKey: key("eventId")) ?? ""
    nextTitle = sharedDefault.string(forKey: key("nextTitle")) ?? ""
    nextSubtitle = sharedDefault.string(forKey: key("nextSubtitle")) ?? ""
    if sharedDefault.object(forKey: key("hasNext")) != nil {
      hasNext = sharedDefault.bool(forKey: key("hasNext"))
    } else {
      hasNext = !nextTitle.isEmpty
    }
    let startMs = sharedDefault.double(forKey: key("segmentStartMs"))
    let endMs = sharedDefault.double(forKey: key("segmentEndMs"))
    segmentStart = Date(timeIntervalSince1970: startMs / 1000)
    segmentEnd = Date(timeIntervalSince1970: endMs / 1000)
  }
}

private func formatTime(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "de_DE")
  formatter.dateFormat = "HH:mm"
  return formatter.string(from: date)
}

private func remainingMinutes(until end: Date, now: Date = Date()) -> Int {
  max(0, Int(ceil(end.timeIntervalSince(now) / 60)))
}

private func compactTitle(_ title: String) -> String {
  let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
  guard trimmed.count > 10 else { return trimmed }
  return String(trimmed.prefix(9)) + "…"
}

private func scheduleDeepLink(for eventId: String) -> URL? {
  guard !eventId.isEmpty else { return nil }
  var components = URLComponents()
  components.scheme = "chronoapp"
  components.host = "schedule"
  components.queryItems = [URLQueryItem(name: "eventId", value: eventId)]
  return components.url
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleColumn: View {
  let title: String
  let subtitle: String
  let alignment: HorizontalAlignment
  var titleSize: CGFloat = 16
  var subtitleSize: CGFloat = 14

  var body: some View {
    VStack(alignment: alignment, spacing: 5) {
      Text(title)
        .font(.system(size: titleSize, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(2)
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
      if !subtitle.isEmpty {
        Text(subtitle)
          .font(.system(size: subtitleSize, weight: .regular))
          .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
          .lineLimit(2)
          .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
      }
    }
    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleNextColumn: View {
  let data: ScheduleLiveData
  let alignment: HorizontalAlignment
  var titleSize: CGFloat = 16
  var subtitleSize: CGFloat = 14

  var body: some View {
    Group {
      if data.hasNext {
        ScheduleColumn(
          title: data.nextTitle,
          subtitle: data.nextSubtitle,
          alignment: alignment,
          titleSize: titleSize,
          subtitleSize: subtitleSize
        )
      }
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleProgressBar: View {
  let progress: Double
  var height: CGFloat = 8

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color(red: 0.16, green: 0.16, blue: 0.16))
        Capsule()
          .fill(Color(red: 0.23, green: 0.30, blue: 0.42))
          .frame(width: max(0, geo.size.width * min(max(progress, 0), 1)))
      }
    }
    .frame(height: height)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleProgressSection: View {
  let data: ScheduleLiveData
  var timeFontSize: CGFloat = 13
  var barHeight: CGFloat = 8
  var horizontalPadding: CGFloat = 0

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        Text(formatTime(data.segmentStart))
          .font(.system(size: timeFontSize, weight: .regular))
          .foregroundColor(.white)
        Spacer()
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
          Text("Noch \(remainingMinutes(until: data.segmentEnd, now: timeline.date)) Min.")
            .font(.system(size: timeFontSize, weight: .regular))
            .foregroundColor(.white)
        }
        Spacer()
        Text(formatTime(data.segmentEnd))
          .font(.system(size: timeFontSize, weight: .regular))
          .foregroundColor(.white)
      }
      TimelineView(.periodic(from: .now, by: 15)) { timeline in
        let total = data.segmentEnd.timeIntervalSince(data.segmentStart)
        let elapsed = timeline.date.timeIntervalSince(data.segmentStart)
        let p = total > 0 ? min(max(elapsed / total, 0), 1) : 1
        ScheduleProgressBar(progress: p, height: barHeight)
      }
    }
    .padding(.horizontal, horizontalPadding)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityLayout {
  let sectionSpacing: CGFloat
  let columnSpacing: CGFloat
  let titleSize: CGFloat
  let subtitleSize: CGFloat
  let timeFontSize: CGFloat
  let barHeight: CGFloat
  let horizontalPadding: CGFloat
  let verticalPadding: CGFloat
  let showsBackground: Bool

  static let lockScreen = ScheduleLiveActivityLayout(
    sectionSpacing: 22,
    columnSpacing: 18,
    titleSize: 19,
    subtitleSize: 16,
    timeFontSize: 15,
    barHeight: 9,
    horizontalPadding: 30,
    verticalPadding: 32,
    showsBackground: true
  )

  // Die DynamicIslandExpandedRegion bringt bereits eigene System-Insets und
  // den dunklen Island-Hintergrund mit. Deshalb hier kein eigener Background
  // und nur minimales vertikales Padding, um doppelte Ränder zu vermeiden.
  static let dynamicIsland = ScheduleLiveActivityLayout(
    sectionSpacing: 20,
    columnSpacing: 16,
    titleSize: 17,
    subtitleSize: 14,
    timeFontSize: 13,
    barHeight: 8,
    horizontalPadding: 10,
    verticalPadding: 6,
    showsBackground: false
  )
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityView: View {
  let data: ScheduleLiveData
  let layout: ScheduleLiveActivityLayout

  var body: some View {
    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
      HStack(alignment: .center, spacing: layout.columnSpacing) {
        ScheduleColumn(
          title: data.currentTitle,
          subtitle: data.currentSubtitle,
          alignment: .leading,
          titleSize: layout.titleSize,
          subtitleSize: layout.subtitleSize
        )
        if data.hasNext {
          Image(systemName: "arrow.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            .frame(width: 20)
        }
        if data.hasNext {
          ScheduleNextColumn(
            data: data,
            alignment: .trailing,
            titleSize: layout.titleSize,
            subtitleSize: layout.subtitleSize
          )
        }
      }
      ScheduleProgressSection(
        data: data,
        timeFontSize: layout.timeFontSize,
        barHeight: layout.barHeight
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, layout.horizontalPadding)
    .padding(.vertical, layout.verticalPadding)
    .background(layout.showsBackground ? Color.black : Color.clear)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityLockScreenView: View {
  let data: ScheduleLiveData

  var body: some View {
    ScheduleLiveActivityView(data: data, layout: .lockScreen)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityDynamicIslandView: View {
  let data: ScheduleLiveData

  var body: some View {
    ScheduleLiveActivityView(data: data, layout: .dynamicIsland)
  }
}

@available(iOSApplicationExtension 16.1, *)
struct ChronoScheduleLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let data = ScheduleLiveData(context: context)
      ScheduleLiveActivityLockScreenView(data: data)
        .widgetURL(scheduleDeepLink(for: data.eventId))
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let data = ScheduleLiveData(context: context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.bottom) {
          ScheduleLiveActivityDynamicIslandView(data: data)
        }
      } compactLeading: {
        if data.hasNext {
          Text(formatTime(data.segmentEnd))
            .font(.footnote.monospacedDigit().weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        } else {
          Text(compactTitle(data.currentTitle))
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
      } compactTrailing: {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
          Text("\(remainingMinutes(until: data.segmentEnd, now: timeline.date))m")
            .font(.footnote.monospacedDigit().weight(.semibold))
            .foregroundColor(.white)
        }
      } minimal: {
        Image(systemName: data.hasNext ? "calendar" : "flag.checkered")
          .font(.body.weight(.semibold))
          .foregroundColor(.white)
      }
      .widgetURL(scheduleDeepLink(for: data.eventId))
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}
