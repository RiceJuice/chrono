import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ChronoWidgetExtensionBundle: WidgetBundle {
  var body: some Widget {
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
  let currentTitle: String
  let currentSubtitle: String
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
    nextTitle = sharedDefault.string(forKey: key("nextTitle")) ?? ""
    nextSubtitle = sharedDefault.string(forKey: key("nextSubtitle")) ?? ""
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

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleColumn: View {
  let title: String
  let subtitle: String
  let alignment: HorizontalAlignment

  var body: some View {
    VStack(alignment: alignment, spacing: 4) {
      Text(title)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(2)
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
      if !subtitle.isEmpty {
        Text(subtitle)
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
          .lineLimit(2)
          .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
      }
    }
    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleProgressBar: View {
  let progress: Double

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
    .frame(height: 6)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct ScheduleLiveActivityView: View {
  let data: ScheduleLiveData

  private var progress: Double {
    let total = data.segmentEnd.timeIntervalSince(data.segmentStart)
    guard total > 0 else { return 1 }
    let elapsed = Date().timeIntervalSince(data.segmentStart)
    return min(max(elapsed / total, 0), 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        ScheduleColumn(title: data.currentTitle, subtitle: data.currentSubtitle, alignment: .leading)
        ScheduleColumn(title: data.nextTitle, subtitle: data.nextSubtitle, alignment: .trailing)
      }
      VStack(spacing: 8) {
        HStack {
          Text(formatTime(data.segmentStart))
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.white)
          Spacer()
          TimelineView(.periodic(from: .now, by: 30)) { timeline in
            Text("Noch \(remainingMinutes(until: data.segmentEnd, now: timeline.date)) Min.")
              .font(.system(size: 12, weight: .regular))
              .foregroundColor(.white)
          }
          Spacer()
          Text(formatTime(data.segmentEnd))
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.white)
        }
        TimelineView(.periodic(from: .now, by: 15)) { timeline in
          let total = data.segmentEnd.timeIntervalSince(data.segmentStart)
          let elapsed = timeline.date.timeIntervalSince(data.segmentStart)
          let p = total > 0 ? min(max(elapsed / total, 0), 1) : 1
          ScheduleProgressBar(progress: p)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color.black)
  }
}

@available(iOSApplicationExtension 16.1, *)
struct ChronoScheduleLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      ScheduleLiveActivityView(data: ScheduleLiveData(context: context))
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let data = ScheduleLiveData(context: context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          ScheduleColumn(title: data.currentTitle, subtitle: data.currentSubtitle, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.trailing) {
          ScheduleColumn(title: data.nextTitle, subtitle: data.nextSubtitle, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ScheduleLiveActivityView(data: data)
        }
      } compactLeading: {
        Text(formatTime(data.segmentEnd))
          .font(.caption2.monospacedDigit())
          .foregroundColor(.white)
      } compactTrailing: {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
          Text("\(remainingMinutes(until: data.segmentEnd, now: timeline.date))m")
            .font(.caption2.monospacedDigit())
            .foregroundColor(.white)
        }
      } minimal: {
        Image(systemName: "calendar")
          .foregroundColor(.white)
      }
    }
  }
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}
