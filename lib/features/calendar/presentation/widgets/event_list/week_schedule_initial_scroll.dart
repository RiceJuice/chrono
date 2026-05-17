import 'dart:math' as math;

import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_navigation.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_viewport.dart';
import 'package:flutter/material.dart';

/// Ob die nahtlose Mobile-ListView auf dieser Bildschirmgröße genutzt wird.
bool weekScheduleUsesMobileSeamlessForSize(Size logicalSize) {
  final shortest = math.min(logicalSize.width, logicalSize.height);
  if (shortest >= kCalendarPhoneLayoutMaxShortestSide) return false;
  return logicalSize.height >= logicalSize.width;
}

int weekScheduleScrollTargetGlobalIndex(
  int selectedGlobalIndex,
  WeekSchedulePanStride stride,
) {
  if (stride == WeekSchedulePanStride.week) {
    return selectedGlobalIndex - (selectedGlobalIndex % 7);
  }
  return selectedGlobalIndex;
}

double weekScheduleOffsetForGlobalIndex(int globalIndex, double dayWidth) =>
    globalIndex * dayWidth;

/// Start-Offset für [ScrollController.initialScrollOffset] (Phone-Portrait).
double? computePhoneSeamlessInitialScrollOffset({
  required Size logicalScreenSize,
  required DateTime day,
}) {
  if (!weekScheduleUsesMobileSeamlessForSize(logicalScreenSize)) {
    return null;
  }

  final innerWidth =
      logicalScreenSize.width - kCalendarTimelineGutterWidth;
  if (innerWidth <= 0) return null;

  final dayWidth = weekSchedulePhoneDayColumnWidthFromInnerWidth(
    innerWidth,
    orientation: Orientation.portrait,
  );
  if (dayWidth <= 0) return null;

  final selectedGlobalIndex = weekScheduleGlobalDayIndex(day);
  final targetGlobalIndex = weekScheduleScrollTargetGlobalIndex(
    selectedGlobalIndex,
    WeekSchedulePanStride.day,
  );
  return weekScheduleOffsetForGlobalIndex(targetGlobalIndex, dayWidth);
}
