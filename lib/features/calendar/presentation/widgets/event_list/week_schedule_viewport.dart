import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:flutter/material.dart';

/// Mindestanzahl sichtbarer Tage im mobilen Wochen-Stundenplan (schmale Portrait-Breite).
const int kWeekScheduleVisibleDaysPhoneMin = 3;

/// Höchstens so viele Tage gleichzeitig im Portrait (nach Breite).
const int kWeekScheduleVisibleDaysPhoneMax = 7;

/// Immer eine volle Woche gleichzeitig im Querformat.
const int kWeekScheduleVisibleDaysLandscape = 7;

/// Zielbreite pro Tag im Portrait; im Querformat gilt fest 7 Tage.
const double kWeekSchedulePhoneDayTargetMinWidth = 112;

/// Stundenhöhe (Pixel pro Stunde) auf schmalen Viewports — etwas höher als
/// Tablet, aber kompakter als frühere 100px, damit die Zeitleiste weniger
/// weit auseinanderzieht.
const double kWeekScheduleHourHeightPhone = 84;

bool weekScheduleIsPhoneViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width < kCalendarTabletBreakpoint;
}

double weekScheduleHourHeightFor(BuildContext context) {
  return weekScheduleIsPhoneViewport(context)
      ? kWeekScheduleHourHeightPhone
      : kWeekScheduleHourHeight;
}

/// Breite einer Tages-Spalte; Portrait: dynamisch 3–7 nach Breite, Querformat: immer 7 Tage.
double weekSchedulePhoneDayColumnWidth(BuildContext context) {
  final w =
      MediaQuery.sizeOf(context).width - kCalendarTimelineGutterWidth;
  return weekSchedulePhoneDayColumnWidthFromInnerWidth(
    w,
    orientation: MediaQuery.orientationOf(context),
  );
}

int weekScheduleVisibleDayCountFromInnerWidth(
  double innerWidth, {
  required Orientation orientation,
}) {
  if (orientation == Orientation.landscape) {
    return kWeekScheduleVisibleDaysLandscape;
  }
  if (innerWidth <= 0) return kWeekScheduleVisibleDaysPhoneMin;
  final byTarget =
      (innerWidth / kWeekSchedulePhoneDayTargetMinWidth).floor();
  return byTarget
      .clamp(kWeekScheduleVisibleDaysPhoneMin, kWeekScheduleVisibleDaysPhoneMax);
}

double weekSchedulePhoneDayColumnWidthFromInnerWidth(
  double innerWidth, {
  required Orientation orientation,
}) {
  final n = weekScheduleVisibleDayCountFromInnerWidth(
    innerWidth,
    orientation: orientation,
  );
  return innerWidth / n;
}
