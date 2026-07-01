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

private func remainingSeconds(until end: Date, now: Date) -> Int {
  max(0, Int(end.timeIntervalSince(now)))
}

private func formatCountdown(seconds: Int) -> String {
  let minutes = seconds / 60
  let secs = seconds % 60
  return String(format: "%d:%02d", minutes, secs)
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

/// Proportionen wie [CalendarDayMarkerPill]: Außenhöhe 9, Inset 1.5, Innenhöhe 6.
@available(iOSApplicationExtension 16.1, *)
private struct PillProgressMetrics {
  let outerHeight: CGFloat

  var contentInset: CGFloat { outerHeight * (1.5 / 9.0) }
  var innerHeight: CGFloat { outerHeight - contentInset * 2 }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleProgressBar: View {
  let progress: Double
  var outerHeight: CGFloat = 15

  private var metrics: PillProgressMetrics { PillProgressMetrics(outerHeight: outerHeight) }

  /// surfaceContainerHighest mit leichtem Weiß-Anteil, analog zur Kalender-Pille.
  private var trackColor: Color {
    Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255)
  }

  var body: some View {
    let inset = metrics.contentInset
    let innerHeight = metrics.innerHeight
    let clampedProgress = min(max(progress, 0), 1)

    GeometryReader { geo in
      let innerWidth = max(0, geo.size.width - inset * 2)

      ZStack(alignment: .leading) {
        Capsule()
          .fill(trackColor)
        Capsule()
          .fill(Color(red: 0.23, green: 0.30, blue: 0.42))
          .frame(width: max(0, innerWidth * clampedProgress), height: innerHeight)
          .padding(.leading, inset)
      }
    }
    .frame(height: outerHeight)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleProgressSection: View {
  let data: ScheduleLiveData
  var timeFontSize: CGFloat = 13
  var barOuterHeight: CGFloat = 15
  var horizontalPadding: CGFloat = 0

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        Text(formatTime(data.segmentStart))
          .font(.system(size: timeFontSize, weight: .regular))
          .foregroundColor(.white)
        Spacer()
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
          Text("Noch \(formatCountdown(remainingSeconds(until: data.segmentEnd, now: timeline.date)))")
            .font(.system(size: timeFontSize, weight: .regular).monospacedDigit())
            .foregroundColor(.white)
        }
        Spacer()
        Text(formatTime(data.segmentEnd))
          .font(.system(size: timeFontSize, weight: .regular))
          .foregroundColor(.white)
      }
      TimelineView(.periodic(from: data.segmentStart, by: 1.0)) { timeline in
        let total = data.segmentEnd.timeIntervalSince(data.segmentStart)
        let elapsed = timeline.date.timeIntervalSince(data.segmentStart)
        let p = total > 0 ? min(max(elapsed / total, 0), 1) : 1
        ScheduleProgressBar(progress: p, outerHeight: barOuterHeight)
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
  let barOuterHeight: CGFloat
  let horizontalPadding: CGFloat
  let verticalPadding: CGFloat
  let showsBackground: Bool

  static let lockScreen = ScheduleLiveActivityLayout(
    sectionSpacing: 22,
    columnSpacing: 18,
    titleSize: 19,
    subtitleSize: 16,
    timeFontSize: 15,
    barOuterHeight: 15,
    horizontalPadding: 30,
    verticalPadding: 32,
    showsBackground: false
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
    barOuterHeight: 12,
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
        barOuterHeight: layout.barOuterHeight
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, layout.horizontalPadding)
    .padding(.vertical, layout.verticalPadding)
    .background(layout.showsBackground ? Color.black : Color.clear)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityLockScreenGlassBackground: View {
  var body: some View {
    if #available(iOSApplicationExtension 26.0, *) {
      Rectangle()
        .fill(.clear)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    } else {
      Rectangle()
        .fill(.ultraThinMaterial)
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityLockScreenView: View {
  let data: ScheduleLiveData
  @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

  var body: some View {
    ScheduleLiveActivityView(data: data, layout: .lockScreen)
      .background {
        if showsWidgetContainerBackground {
          ScheduleLiveActivityLockScreenGlassBackground()
            .ignoresSafeArea()
        }
      }
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
        .activityBackgroundTint(.clear)
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
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
          Text(formatCountdown(remainingSeconds(until: data.segmentEnd, now: timeline.date)))
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
