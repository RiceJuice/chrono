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

private func timetableDeepLink(for dayDate: String) -> URL? {
  guard !dayDate.isEmpty else { return nil }
  var components = URLComponents()
  components.scheme = "chronoapp"
  components.host = "timetable"
  components.queryItems = [URLQueryItem(name: "date", value: dayDate)]
  return components.url
}

private func readKind(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> String {
  let key = context.attributes.prefixedKey("kind")
  return sharedDefault.string(forKey: key) ?? "schedule"
}

private struct TimetableSegment: Codable {
  let id: String
  let type: String
  let title: String
  let shortTitle: String?
  let subtitle: String
  let startMs: Double
  let endMs: Double
  let accentColor: String
  let imageUrl: String?

  var displayShortTitle: String {
    let trimmed = (shortTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty { return trimmed }
    let titleTrimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard titleTrimmed.count > 3 else { return titleTrimmed }
    return String(titleTrimmed.prefix(3))
  }
}

private struct TimetableResolvedSegment {
  let index: Int
  let title: String
  let subtitle: String
  let currentShortTitle: String
  let segmentStart: Date
  let segmentEnd: Date
  let accentColor: Color
  let isMeal: Bool
  let imageUrl: String?
  let hasNext: Bool
  let nextTitle: String
  let nextSubtitle: String
  let nextShortTitle: String
  let remainingLessons: Int
  let isPreStart: Bool
}

private struct TimetableLiveData {
  let dayDate: String
  let segments: [TimetableSegment]
  let activityStartMs: Double

  init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
    func key(_ name: String) -> String {
      context.attributes.prefixedKey(name)
    }
    dayDate = sharedDefault.string(forKey: key("dayDate")) ?? ""
    activityStartMs = sharedDefault.double(forKey: key("activityStartMs"))
    let rawJson = sharedDefault.string(forKey: key("segmentsJson")) ?? "[]"
    if let data = rawJson.data(using: .utf8),
       let decoded = try? JSONDecoder().decode([TimetableSegment].self, from: data) {
      segments = decoded
    } else {
      segments = []
    }
  }

  func resolve(at now: Date) -> TimetableResolvedSegment? {
    guard !segments.isEmpty else { return nil }
    let nowMs = now.timeIntervalSince1970 * 1000
    let activityStart = Date(timeIntervalSince1970: activityStartMs / 1000)
    let first = segments[0]

    if nowMs < first.startMs {
      let next = segments.count > 1 ? segments[1] : nil
      return TimetableResolvedSegment(
        index: 0,
        title: first.title,
        subtitle: first.subtitle,
        currentShortTitle: first.displayShortTitle,
        segmentStart: activityStart,
        segmentEnd: Date(timeIntervalSince1970: first.startMs / 1000),
        accentColor: parseHexColor(first.accentColor),
        isMeal: first.type == "meal",
        imageUrl: first.imageUrl,
        hasNext: next != nil,
        nextTitle: next?.title ?? "",
        nextSubtitle: next?.subtitle ?? "",
        nextShortTitle: next?.displayShortTitle ?? "",
        remainingLessons: remainingLessonCount(fromIndex: 0, nowMs: nowMs),
        isPreStart: true
      )
    }

    for (index, segment) in segments.enumerated() {
      if nowMs < segment.endMs {
        let next = index + 1 < segments.count ? segments[index + 1] : nil
        return TimetableResolvedSegment(
          index: index,
          title: segment.title,
          subtitle: segment.subtitle,
          currentShortTitle: segment.displayShortTitle,
          segmentStart: Date(timeIntervalSince1970: segment.startMs / 1000),
          segmentEnd: Date(timeIntervalSince1970: segment.endMs / 1000),
          accentColor: parseHexColor(segment.accentColor),
          isMeal: segment.type == "meal",
          imageUrl: segment.imageUrl,
          hasNext: next != nil,
          nextTitle: next?.title ?? "",
          nextSubtitle: next?.subtitle ?? "",
          nextShortTitle: next?.displayShortTitle ?? "",
          remainingLessons: remainingLessonCount(fromIndex: index, nowMs: nowMs),
          isPreStart: false
        )
      }
    }
    return nil
  }

  private func remainingLessonCount(fromIndex: Int, nowMs: Double) -> Int {
    var count = 0
    for i in fromIndex..<segments.count {
      let segment = segments[i]
      if segment.type != "lesson" { continue }
      if i == fromIndex && nowMs >= segment.endMs { continue }
      count += 1
    }
    return count
  }
}

private func parseHexColor(_ hex: String) -> Color {
  var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
  if cleaned.hasPrefix("#") {
    cleaned.removeFirst()
  }
  guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
    return Color(red: 0.07, green: 0.31, blue: 0.19)
  }
  let r = Double((value >> 16) & 0xFF) / 255.0
  let g = Double((value >> 8) & 0xFF) / 255.0
  let b = Double(value & 0xFF) / 255.0
  return Color(red: r, green: g, blue: b)
}

private func remainingLessonsLabel(_ count: Int) -> String {
  if count == 1 { return "Noch 1 Stunde" }
  return "Noch \(count) Stunden"
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
private struct TimetableAccentProgressBar: View {
  let progress: Double
  let accentColor: Color
  var outerHeight: CGFloat = 15

  private var metrics: PillProgressMetrics { PillProgressMetrics(outerHeight: outerHeight) }

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
          .fill(accentColor.opacity(0.92))
          .frame(width: max(0, innerWidth * clampedProgress), height: innerHeight)
          .padding(.leading, inset)
      }
    }
    .frame(height: outerHeight)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableMealThumbnail: View {
  let imageUrl: String?

  var body: some View {
    Group {
      if let imageUrl, let url = URL(string: imageUrl), !imageUrl.isEmpty {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
          default:
            Rectangle()
              .fill(Color(red: 0.20, green: 0.20, blue: 0.20))
          }
        }
      }
    }
    .frame(width: 34, height: 34)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableCountdownText: View {
  let segmentStart: Date
  let segmentEnd: Date
  var fontSize: CGFloat = 13
  var fontWeight: Font.Weight = .regular

  var body: some View {
    Group {
      if segmentEnd > segmentStart {
        (Text("Noch ")
          + Text(
            timerInterval: segmentStart...segmentEnd,
            countsDown: true,
            showsHours: false
          ))
      } else {
        Text("Noch 0:00")
      }
    }
    .font(.system(size: fontSize, weight: fontWeight).monospacedDigit())
    .foregroundColor(.white)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableProgressSection: View {
  let segmentStart: Date
  let segmentEnd: Date
  let accentColor: Color
  let now: Date
  var timeFontSize: CGFloat = 13
  var barOuterHeight: CGFloat = 15

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        HStack {
          Text(formatTime(segmentStart))
            .font(.system(size: timeFontSize, weight: .regular))
            .foregroundColor(.white)
          Spacer(minLength: 0)
          Text(formatTime(segmentEnd))
            .font(.system(size: timeFontSize, weight: .regular))
            .foregroundColor(.white)
        }
        TimetableCountdownText(
          segmentStart: segmentStart,
          segmentEnd: segmentEnd,
          fontSize: timeFontSize
        )
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
      }
      let total = segmentEnd.timeIntervalSince(segmentStart)
      let elapsed = now.timeIntervalSince(segmentStart)
      let p = total > 0 ? min(max(elapsed / total, 0), 1) : 1
      TimetableAccentProgressBar(
        progress: p,
        accentColor: accentColor,
        outerHeight: barOuterHeight
      )
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableLiveActivityView: View {
  let data: TimetableLiveData
  let layout: ScheduleLiveActivityLayout
  var showsRemainingLessons: Bool = true

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
      if let resolved = data.resolve(at: timeline.date) {
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
          HStack(alignment: .top, spacing: layout.columnSpacing) {
            ScheduleColumn(
              title: resolved.title,
              subtitle: resolved.subtitle,
              alignment: .leading,
              titleSize: layout.titleSize,
              subtitleSize: layout.subtitleSize
            )
            if resolved.isMeal, let imageUrl = resolved.imageUrl, !imageUrl.isEmpty {
              TimetableMealThumbnail(imageUrl: imageUrl)
                .frame(width: 30)
            } else if resolved.hasNext {
              Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
                .frame(width: 16)
                .padding(.top, 2)
              ScheduleColumn(
                title: resolved.nextTitle,
                subtitle: resolved.nextSubtitle,
                alignment: .trailing,
                titleSize: layout.titleSize,
                subtitleSize: layout.subtitleSize
              )
            }
          }

          if showsRemainingLessons && resolved.remainingLessons > 0 {
            Text(remainingLessonsLabel(resolved.remainingLessons))
              .font(.system(size: layout.timeFontSize, weight: .medium))
              .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
          }

          TimetableProgressSection(
            segmentStart: resolved.segmentStart,
            segmentEnd: resolved.segmentEnd,
            accentColor: resolved.accentColor,
            now: timeline.date,
            timeFontSize: layout.timeFontSize,
            barOuterHeight: layout.barOuterHeight
          )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.top, layout.topPadding)
        .padding(.bottom, layout.bottomPadding)
      }
    }
  }
}

/// Farbig hinterlegtes Kürzel-Badge für die linke Dynamic-Island-Region.
/// Bleibt fernab der Sensor-Aussparung und ersetzt lange Fachnamen dort,
/// wo ohnehin nur wenig Platz ist.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandLeadingBadge: View {
  let data: TimetableLiveData

  var body: some View {
    TimelineView(.periodic(from: .now, by: 60.0)) { timeline in
      if let resolved = data.resolve(at: timeline.date) {
        ZStack {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(resolved.accentColor.opacity(0.92))
          if resolved.isMeal, let imageUrl = resolved.imageUrl, !imageUrl.isEmpty {
            TimetableMealThumbnail(imageUrl: imageUrl)
              .frame(width: 40, height: 40)
          } else {
            Text(resolved.currentShortTitle)
              .font(.system(size: 15, weight: .bold))
              .foregroundColor(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.6)
              .padding(.horizontal, 4)
          }
        }
        .frame(width: 40, height: 40)
      }
    }
  }
}

/// Aktuelles Fach + Raum, mittig zwischen der Sensor-Aussparung.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandCenterView: View {
  let data: TimetableLiveData

  var body: some View {
    TimelineView(.periodic(from: .now, by: 60.0)) { timeline in
      if let resolved = data.resolve(at: timeline.date) {
        VStack(spacing: 3) {
          Text(resolved.title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
          if !resolved.subtitle.isEmpty {
            Text(resolved.subtitle)
              .font(.system(size: 12, weight: .regular))
              .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
          }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
      }
    }
  }
}

/// Ausblick auf das nächste Fach bzw. verbleibende Stunden, rechts neben
/// der Sensor-Aussparung.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandTrailingView: View {
  let data: TimetableLiveData

  var body: some View {
    TimelineView(.periodic(from: .now, by: 60.0)) { timeline in
      if let resolved = data.resolve(at: timeline.date) {
        VStack(alignment: .trailing, spacing: 3) {
          if resolved.hasNext {
            Text("Nächstes")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            Text(resolved.nextShortTitle.isEmpty ? resolved.nextTitle : resolved.nextShortTitle)
              .font(.system(size: 15, weight: .bold))
              .foregroundColor(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
          } else if resolved.remainingLessons > 0 {
            Text("Noch")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            Text("\(resolved.remainingLessons)")
              .font(.system(size: 15, weight: .bold))
              .foregroundColor(.white)
          } else {
            Image(systemName: "flag.checkered")
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(.white)
          }
        }
        .frame(minWidth: 40)
      }
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandBottomView: View {
  let data: TimetableLiveData
  let layout: ScheduleLiveActivityLayout

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
      if let resolved = data.resolve(at: timeline.date) {
        TimetableProgressSection(
          segmentStart: resolved.segmentStart,
          segmentEnd: resolved.segmentEnd,
          accentColor: resolved.accentColor,
          now: timeline.date,
          timeFontSize: layout.timeFontSize,
          barOuterHeight: layout.barOuterHeight
        )
        .padding(.horizontal, layout.horizontalPadding)
        .padding(.top, layout.topPadding)
        .padding(.bottom, layout.bottomPadding)
      }
    }
  }
}

private func timetableCompactLeadingLabel(
  for resolved: TimetableResolvedSegment?
) -> String {
  guard let resolved else { return "—" }
  if resolved.isPreStart || !resolved.hasNext {
    return resolved.currentShortTitle
  }
  return resolved.nextShortTitle
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableLiveActivityLockScreenView: View {
  let data: TimetableLiveData
  @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

  var body: some View {
    TimetableLiveActivityView(data: data, layout: .timetableLockScreen)
      .background {
        if showsWidgetContainerBackground {
          ScheduleLiveActivityLockScreenGlassBackground()
            .ignoresSafeArea()
        }
      }
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
      ZStack {
        HStack {
          Text(formatTime(data.segmentStart))
            .font(.system(size: timeFontSize, weight: .regular))
            .foregroundColor(.white)
          Spacer(minLength: 0)
          Text(formatTime(data.segmentEnd))
            .font(.system(size: timeFontSize, weight: .regular))
            .foregroundColor(.white)
        }
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
          Text("Noch \(formatCountdown(seconds: remainingSeconds(until: data.segmentEnd, now: timeline.date)))")
            .font(.system(size: timeFontSize, weight: .regular).monospacedDigit())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
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
  let topPadding: CGFloat
  let bottomPadding: CGFloat
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
    topPadding: 32,
    bottomPadding: 32,
    showsBackground: false
  )

  static let timetableLockScreen = ScheduleLiveActivityLayout(
    sectionSpacing: 16,
    columnSpacing: 14,
    titleSize: 19,
    subtitleSize: 15,
    timeFontSize: 15,
    barOuterHeight: 14,
    horizontalPadding: 28,
    verticalPadding: 24,
    topPadding: 28,
    bottomPadding: 22,
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
    topPadding: 6,
    bottomPadding: 6,
    showsBackground: false
  )

  static let timetableDynamicIsland = ScheduleLiveActivityLayout(
    sectionSpacing: 8,
    columnSpacing: 10,
    titleSize: 16,
    subtitleSize: 12,
    timeFontSize: 12,
    barOuterHeight: 10,
    horizontalPadding: 16,
    verticalPadding: 2,
    topPadding: 8,
    bottomPadding: 12,
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

/// Event-Ablaufplan: schwarze Fläche mit Liquid-Glass-Rand (Lockscreen).
@available(iOSApplicationExtension 16.1, *)
private struct ScheduleEventLiveActivityLockScreenBackground: View {
  private let cornerRadius: CGFloat = 22

  var body: some View {
    if #available(iOSApplicationExtension 26.0, *) {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.black)
        .padding(1.5)
        .background {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.clear)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        }
    } else {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.black)
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
        }
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
          ScheduleEventLiveActivityLockScreenBackground()
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
      let kind = readKind(context: context)
      if kind == "timetable" {
        let data = TimetableLiveData(context: context)
        TimetableLiveActivityLockScreenView(data: data)
          .widgetURL(timetableDeepLink(for: data.dayDate))
          .activityBackgroundTint(.clear)
          .activitySystemActionForegroundColor(.white)
      } else {
        let data = ScheduleLiveData(context: context)
        ScheduleLiveActivityLockScreenView(data: data)
          .widgetURL(scheduleDeepLink(for: data.eventId))
          .activityBackgroundTint(.black)
          .activitySystemActionForegroundColor(.white)
      }
    } dynamicIsland: { context in
      let kind = readKind(context: context)
      if kind == "timetable" {
        let data = TimetableLiveData(context: context)
        return DynamicIsland {
          DynamicIslandExpandedRegion(.leading) {
            TimetableDynamicIslandLeadingBadge(data: data)
          }
          DynamicIslandExpandedRegion(.center) {
            TimetableDynamicIslandCenterView(data: data)
          }
          DynamicIslandExpandedRegion(.trailing) {
            TimetableDynamicIslandTrailingView(data: data)
          }
          DynamicIslandExpandedRegion(.bottom) {
            TimetableDynamicIslandBottomView(data: data, layout: .timetableDynamicIsland)
          }
        } compactLeading: {
          let resolved = data.resolve(at: Date())
          Text(timetableCompactLeadingLabel(for: resolved))
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        } compactTrailing: {
          if let resolved = data.resolve(at: Date()), resolved.segmentEnd > resolved.segmentStart {
            Text(
              timerInterval: resolved.segmentStart...resolved.segmentEnd,
              countsDown: true,
              showsHours: false
            )
              .font(.footnote.monospacedDigit().weight(.semibold))
              .foregroundColor(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }
        } minimal: {
          Image(systemName: "book")
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
        }
        .widgetURL(timetableDeepLink(for: data.dayDate))
      }

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
          Text(formatCountdown(seconds: remainingSeconds(until: data.segmentEnd, now: timeline.date)))
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
