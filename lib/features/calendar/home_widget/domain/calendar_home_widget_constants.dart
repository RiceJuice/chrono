import 'package:flutter/material.dart';

import '../../live_activity/live_activity_constants.dart';

/// iOS Widget-Kind (muss mit Swift `kind` übereinstimmen).
const String kCalendarHomeWidgetIosName = 'ChronoCalendarHomeWidget';

/// Android [HomeWidgetProvider]-Klasse (ohne Package-Prefix).
const String kCalendarHomeWidgetAndroidName = 'CalendarHomeWidgetProvider';

/// Deep Link beim Antippen des Widgets.
const String kCalendarHomeWidgetDeepLinkHost = 'calendar';

String get kCalendarHomeWidgetDeepLink =>
    '$kLiveActivityUrlScheme://$kCalendarHomeWidgetDeepLinkHost';

/// Deep Link, wenn die Nutzer:in das Kalender-Homescreen-Widget antippt.
bool isCalendarHomeWidgetDeepLink(Uri uri) {
  return uri.scheme == kLiveActivityUrlScheme &&
      uri.host == kCalendarHomeWidgetDeepLinkHost;
}

/// Android: zuletzt gemeldete Widget-Größe (dp) aus [AppWidgetManager].
const String kCalendarHomeWidgetAndroidWidthDpKey = 'calendar_widget_width_dp';
const String kCalendarHomeWidgetAndroidHeightDpKey = 'calendar_widget_height_dp';
const String kCalendarHomeWidgetAndroidDensityKey = 'calendar_widget_density';

/// Horizont für Termin-Laden ab heute.
const int kCalendarHomeWidgetDayHorizon = 14;

String calendarHomeWidgetImageKey({
  required String sizeToken,
  required bool isDark,
}) {
  return 'calendar_widget_${sizeToken}_${isDark ? 'dark' : 'light'}';
}

class CalendarHomeWidgetRenderTarget {
  const CalendarHomeWidgetRenderTarget({
    required this.logicalSize,
    required this.sizeToken,
  });

  final Size logicalSize;

  /// `medium`, `large` oder `android` — Teil des SharedPreferences-Keys.
  final String sizeToken;

  String imageKey({required bool isDark}) =>
      calendarHomeWidgetImageKey(sizeToken: sizeToken, isDark: isDark);

  static const medium = CalendarHomeWidgetRenderTarget(
    logicalSize: Size(364, 170),
    sizeToken: 'medium',
  );

  static const large = CalendarHomeWidgetRenderTarget(
    logicalSize: Size(364, 382),
    sizeToken: 'large',
  );

  factory CalendarHomeWidgetRenderTarget.android({
    required double widthDp,
    required double heightDp,
  }) {
    return CalendarHomeWidgetRenderTarget(
      logicalSize: Size(widthDp, heightDp),
      sizeToken: 'android',
    );
  }
}
