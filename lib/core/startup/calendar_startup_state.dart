import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_view_options.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_initial_scroll.dart';
import 'package:flutter/material.dart';

/// Vorberechneter Kalender-Zustand vor dem Verlassen des Ladescreens.
class CalendarStartupState {
  CalendarStartupState._();

  static double? phoneSeamlessScrollOffset;

  static void preload({
    required Size logicalScreenSize,
    required CalendarViewMode viewMode,
  }) {
    phoneSeamlessScrollOffset = viewMode == CalendarViewMode.week
        ? computePhoneSeamlessInitialScrollOffset(
            logicalScreenSize: logicalScreenSize,
            day: AppDateTime.todayLocal(),
          )
        : null;
  }

  static void reset() {
    phoneSeamlessScrollOffset = null;
  }
}
