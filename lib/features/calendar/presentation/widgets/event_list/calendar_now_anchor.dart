import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/domain/models/event_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Gemeinsame „Jetzt“-Anker-Logik für Tagesliste und Ablaufplan.
abstract final class CalendarNowAnchor {
  CalendarNowAnchor._();

  static const double defaultRevealAlignment = 0.28;

  static int entryIndexForNowAnchor(
    List<CalendarEntry> entries, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    for (var i = 0; i < entries.length; i++) {
      final localEnd = AppDateTime.toLocal(entries[i].endTime);
      if (localEnd.isAfter(clock)) return i;
    }
    return entries.length;
  }

  static int scheduleIndexForNowAnchor(
    List<EventSchedule> schedules, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    for (var i = 0; i < schedules.length; i++) {
      final end = scheduleEffectiveEnd(schedules[i]);
      if (AppDateTime.toLocal(end).isAfter(clock)) return i;
    }
    return schedules.length;
  }

  static DateTime scheduleEffectiveEnd(EventSchedule schedule) {
    return schedule.endTime ?? schedule.startTime;
  }

  static bool scheduleIsPast(EventSchedule schedule, {DateTime? now}) {
    return AppDateTime.isPastInstant(
      scheduleEffectiveEnd(schedule),
      now: now,
    );
  }

  static bool scheduleApplyPastStyling(
    EventSchedule schedule, {
    DateTime? now,
  }) {
    return AppDateTime.isTodayLocal(schedule.startTime, now: now);
  }

  /// Springt zum Anker; gibt `true` zurück, wenn der Sprung ausgeführt wurde.
  /// `false`, wenn der Anker noch nicht gebaut/gemessen ist (z. B. lazy Liste).
  static bool jumpToAnchor({
    required GlobalKey anchorKey,
    required ScrollController controller,
    double alignment = defaultRevealAlignment,
  }) {
    final anchorContext = anchorKey.currentContext;
    if (anchorContext == null) return false;
    final anchorRenderObject = anchorContext.findRenderObject();
    if (anchorRenderObject == null || !controller.hasClients) return false;

    final viewport = RenderAbstractViewport.maybeOf(anchorRenderObject);
    if (viewport == null) return false;

    final position = controller.position;
    final targetOffset = viewport
        .getOffsetToReveal(anchorRenderObject, alignment)
        .offset;
    controller.jumpTo(
      targetOffset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
    return true;
  }

  /// Versucht den Sprung nach dem Layout und fasst mehrfach nach, bis der
  /// Anker tatsächlich gebaut ist (lazy Slivers werden erst beim Bedarf gebaut).
  ///
  /// [shouldContinue] wird vor jedem Versuch geprüft — z. B. um bei Nutzer-Scroll
  /// alle ausstehenden Retries sofort abzubrechen.
  static void scheduleInitialJump({
    required bool Function() jump,
    bool Function()? shouldContinue,
    int maxAttempts = 8,
    Duration retryDelay = const Duration(milliseconds: 48),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptJump(
        jump: jump,
        shouldContinue: shouldContinue,
        remainingAttempts: maxAttempts,
        delay: retryDelay,
      );
    });
  }

  static void _attemptJump({
    required bool Function() jump,
    required bool Function()? shouldContinue,
    required int remainingAttempts,
    required Duration delay,
  }) {
    if (shouldContinue != null && !shouldContinue()) return;
    if (jump() || remainingAttempts <= 1) return;
    Future<void>.delayed(
      delay,
      () => _attemptJump(
        jump: jump,
        shouldContinue: shouldContinue,
        remainingAttempts: remainingAttempts - 1,
        delay: delay,
      ),
    );
  }
}
