import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:flutter/material.dart';

/// Anzahl gleichzeitig sichtbarer Tage im mobilen Wochen-Stundenplan.
const int kWeekScheduleVisibleDaysPhone = 3;

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

/// Breite einer Tages-Spalte bei 3 sichtbaren Tagen (ohne linke Zeitachse).
double weekSchedulePhoneDayColumnWidth(BuildContext context) {
  final w =
      MediaQuery.sizeOf(context).width - kCalendarTimelineGutterWidth;
  return weekSchedulePhoneDayColumnWidthFromInnerWidth(w);
}

double weekSchedulePhoneDayColumnWidthFromInnerWidth(double innerWidth) {
  return innerWidth / kWeekScheduleVisibleDaysPhone;
}
