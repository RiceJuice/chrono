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

/// Stundenplan: primär payload-gesteuert (wie Schedule), segmentsJson nur App-Fallback.
private struct TimetableLiveData {
  let dayDate: String
  let currentTitle: String
  let currentSubtitle: String
  let hasNext: Bool
  let nextTitle: String
  let nextSubtitle: String
  let segmentStart: Date
  let segmentEnd: Date
  let accentColor: Color
  let isMeal: Bool
  let imageUrl: String?
  let mealImagePath: String?
  let remainingLessons: Int

  init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
    func key(_ name: String) -> String {
      context.attributes.prefixedKey(name)
    }
    dayDate = sharedDefault.string(forKey: key("dayDate")) ?? ""
    currentTitle = sharedDefault.string(forKey: key("currentTitle")) ?? ""
    currentSubtitle = sharedDefault.string(forKey: key("currentSubtitle")) ?? ""
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
    let accentHex = sharedDefault.string(forKey: key("accentColor")) ?? "#124E30"
    accentColor = parseHexColor(accentHex)
    isMeal = sharedDefault.bool(forKey: key("isMeal"))
    imageUrl = sharedDefault.string(forKey: key("imageUrl"))
    mealImagePath = sharedDefault.string(forKey: key("mealImage"))
    remainingLessons = Int(sharedDefault.integer(forKey: key("remainingLessons")))
  }

  var compactLeadingLabel: String {
    let trimmed = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count > 3 else { return trimmed.isEmpty ? "—" : trimmed }
    return String(trimmed.prefix(3))
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

/// Systemanimierter Fortschrittsbalken, direkt an den nativen Zeit-Timer
/// von `ProgressView(timerInterval:)` gekoppelt.
///
/// Wichtig: `configuration.fractionCompleted` einer `timerInterval`-basierten
/// `ProgressView` wird von iOS **nur** dann laufend aktualisiert, wenn der
/// *Standard*-Stil verwendet wird. Sobald ein eigener `ProgressViewStyle`
/// (z. B. via `GeometryReader` + `configuration.fractionCompleted`) zum
/// Einsatz kommt, bleibt der Wert bei `0` bzw. dem Startwert stehen – der
/// Balken erscheint dann leer/gar nicht mehr befüllt (bekannte iOS-
/// Einschränkung von ActivityKit/SwiftUI, siehe u. a. SerialCoder.dev sowie
/// mehrere Apple-Forum-/Stack-Overflow-Reports). Deshalb hier bewusst der
/// Standard-Stil (rein lokal, ohne App-Prozess von der Systemuhr
/// interpoliert) und nur per View-Modifier (Farbe, Form, Höhe) angepasst.
@available(iOSApplicationExtension 16.1, *)
private struct SegmentTimerProgressBar: View {
  let segmentStart: Date
  let segmentEnd: Date
  var fillColor: Color
  var outerHeight: CGFloat = 15

  private var trackColor: Color {
    Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255)
  }

  /// Native Balkendicke der Standard-`ProgressView` (linear), auf die wir
  /// per `scaleEffect` hochskalieren. `.frame(height:)` allein beeinflusst
  /// die gerenderte Balkendicke des Systemstils nicht.
  private var baseBarHeight: CGFloat { 4 }

  var body: some View {
    let metrics = PillProgressMetrics(outerHeight: outerHeight)
    let verticalScale = metrics.innerHeight / baseBarHeight

    progressView
      .tint(fillColor)
      .background(trackColor)
      .clipShape(Capsule())
      .scaleEffect(x: 1, y: verticalScale, anchor: .center)
      .frame(height: outerHeight)
  }

  @ViewBuilder
  private var progressView: some View {
    if segmentEnd > segmentStart {
      ProgressView(
        timerInterval: segmentStart...segmentEnd,
        countsDown: false,
        label: { EmptyView() },
        currentValueLabel: { EmptyView() }
      )
      .labelsHidden()
    } else {
      ProgressView(value: 1)
        .labelsHidden()
    }
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableMealImageView: View {
  let appGroupPath: String?
  let remoteUrl: String?
  var width: CGFloat = 34
  var height: CGFloat = 34
  var cornerRadius: CGFloat? = nil
  var fillsAvailableWidth: Bool = false

  private var resolvedCornerRadius: CGFloat {
    cornerRadius ?? height * 0.18
  }

  var body: some View {
    Group {
      if let appGroupPath,
         !appGroupPath.isEmpty,
         let uiImage = UIImage(contentsOfFile: appGroupPath) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      } else if let remoteUrl,
                let url = URL(string: remoteUrl),
                !remoteUrl.isEmpty {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
          default:
            mealPlaceholder
          }
        }
      } else {
        mealPlaceholder
      }
    }
    .frame(
      minWidth: fillsAvailableWidth ? 0 : width,
      maxWidth: fillsAvailableWidth ? .infinity : width,
      minHeight: height,
      maxHeight: height
    )
    .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
  }

  private var mealPlaceholder: some View {
    Rectangle()
      .fill(Color(red: 0.20, green: 0.20, blue: 0.20))
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct SegmentTimeCountdownRow: View {
  let segmentStart: Date
  let segmentEnd: Date
  var timeFontSize: CGFloat = 13

  var body: some View {
    HStack(spacing: 4) {
      Text(formatTime(segmentStart))
        .font(.system(size: timeFontSize, weight: .regular))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
      TimetableCountdownText(
        segmentStart: segmentStart,
        segmentEnd: segmentEnd,
        fontSize: timeFontSize
      )
      .frame(maxWidth: .infinity, alignment: .center)
      Text(formatTime(segmentEnd))
        .font(.system(size: timeFontSize, weight: .regular))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
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
private struct LiveActivityProgressSection: View {
  let segmentStart: Date
  let segmentEnd: Date
  let fillColor: Color
  var timeFontSize: CGFloat = 13
  var barOuterHeight: CGFloat = 15
  var horizontalPadding: CGFloat = 0
  var rowSpacing: CGFloat = 10

  var body: some View {
    VStack(spacing: rowSpacing) {
      SegmentTimeCountdownRow(
        segmentStart: segmentStart,
        segmentEnd: segmentEnd,
        timeFontSize: timeFontSize
      )
      SegmentTimerProgressBar(
        segmentStart: segmentStart,
        segmentEnd: segmentEnd,
        fillColor: fillColor,
        outerHeight: barOuterHeight
      )
    }
    .padding(.horizontal, horizontalPadding)
  }
}

@available(iOSApplicationExtension 16.1, *)
private struct TimetableLiveActivityView: View {
  let data: TimetableLiveData
  let layout: ScheduleLiveActivityLayout
  var showsRemainingLessons: Bool = true

  var body: some View {
    VStack(alignment: .leading, spacing: layout.sectionSpacing) {
      HStack(alignment: .top, spacing: layout.columnSpacing) {
        ScheduleColumn(
          title: data.currentTitle,
          subtitle: data.currentSubtitle,
          alignment: .leading,
          titleSize: layout.titleSize,
          subtitleSize: layout.subtitleSize
        )
        if data.isMeal {
          Spacer(minLength: 8)
          TimetableMealImageView(
            appGroupPath: data.mealImagePath,
            remoteUrl: data.imageUrl,
            width: layout.titleSize + 18,
            height: layout.titleSize + 18
          )
        } else if data.hasNext {
          Image(systemName: "arrow.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
            .frame(width: 16)
            .padding(.top, 2)
          ScheduleColumn(
            title: data.nextTitle,
            subtitle: data.nextSubtitle,
            alignment: .trailing,
            titleSize: layout.titleSize,
            subtitleSize: layout.subtitleSize
          )
        }
      }

      if data.isMeal {
        TimetableMealImageView(
          appGroupPath: data.mealImagePath,
          remoteUrl: data.imageUrl,
          height: 92,
          cornerRadius: 14,
          fillsAvailableWidth: true
        )
      }

      if showsRemainingLessons && data.remainingLessons > 0 {
        Text(remainingLessonsLabel(data.remainingLessons))
          .font(.system(size: layout.timeFontSize, weight: .medium))
          .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
      }

      LiveActivityProgressSection(
        segmentStart: data.segmentStart,
        segmentEnd: data.segmentEnd,
        fillColor: data.accentColor.opacity(0.92),
        timeFontSize: layout.timeFontSize,
        barOuterHeight: layout.barOuterHeight,
        rowSpacing: 6
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, layout.horizontalPadding)
    .padding(.top, layout.topPadding)
    .padding(.bottom, layout.bottomPadding)
  }
}

/// Farbig hinterlegtes Kürzel-Badge für die linke Dynamic-Island-Region.
/// Bleibt fernab der Sensor-Aussparung und ersetzt lange Fachnamen dort,
/// wo ohnehin nur wenig Platz ist.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandLeadingBadge: View {
  let data: TimetableLiveData

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(data.accentColor.opacity(0.92))
      if data.isMeal {
        TimetableMealImageView(
          appGroupPath: data.mealImagePath,
          remoteUrl: data.imageUrl,
          width: 40,
          height: 40,
          cornerRadius: 12
        )
      } else {
        Text(data.compactLeadingLabel)
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

/// Aktuelles Fach + Raum, mittig zwischen der Sensor-Aussparung.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandCenterView: View {
  let data: TimetableLiveData

  var body: some View {
    VStack(spacing: 3) {
      Text(data.currentTitle)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      if !data.currentSubtitle.isEmpty {
        Text(data.currentSubtitle)
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

/// Ausblick auf das nächste Fach bzw. verbleibende Stunden, rechts neben
/// der Sensor-Aussparung.
@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandTrailingView: View {
  let data: TimetableLiveData

  var body: some View {
    VStack(alignment: .trailing, spacing: 3) {
      if data.hasNext {
        Text("Nächstes")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
        Text(compactTitle(data.nextTitle))
          .font(.system(size: 15, weight: .bold))
          .foregroundColor(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      } else if data.remainingLessons > 0 {
        Text("Noch")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(Color(red: 0.54, green: 0.54, blue: 0.54))
        Text("\(data.remainingLessons)")
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

@available(iOSApplicationExtension 16.1, *)
private struct TimetableDynamicIslandBottomView: View {
  let data: TimetableLiveData
  let layout: ScheduleLiveActivityLayout

  var body: some View {
    LiveActivityProgressSection(
      segmentStart: data.segmentStart,
      segmentEnd: data.segmentEnd,
      fillColor: data.accentColor.opacity(0.92),
      timeFontSize: layout.timeFontSize,
      barOuterHeight: layout.barOuterHeight,
      rowSpacing: 6
    )
    .padding(.bottom, layout.bottomPadding)
  }
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

  private var scheduleFillColor: Color {
    Color(red: 0.23, green: 0.30, blue: 0.42)
  }

  var body: some View {
    LiveActivityProgressSection(
      segmentStart: data.segmentStart,
      segmentEnd: data.segmentEnd,
      fillColor: scheduleFillColor,
      timeFontSize: timeFontSize,
      barOuterHeight: barOuterHeight,
      horizontalPadding: horizontalPadding
    )
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
          Text(data.compactLeadingLabel)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        } compactTrailing: {
          if data.segmentEnd > data.segmentStart {
            Text(
              timerInterval: data.segmentStart...data.segmentEnd,
              countsDown: true,
              showsHours: false
            )
              .font(.subheadline.monospacedDigit().weight(.semibold))
              .foregroundColor(.white)
              .lineLimit(1)
              .minimumScaleFactor(0.85)
              .frame(maxWidth: .infinity, alignment: .trailing)
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
        if data.segmentEnd > data.segmentStart {
          Text(
            timerInterval: data.segmentStart...data.segmentEnd,
            countsDown: true,
            showsHours: false
          )
            .font(.footnote.monospacedDigit().weight(.semibold))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
