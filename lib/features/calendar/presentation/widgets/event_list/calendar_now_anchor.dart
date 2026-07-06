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
      final end = scheduleEffectiveEndAt(schedules, i);
      if (AppDateTime.toLocal(end).isAfter(clock)) return i;
    }
    return schedules.length;
  }

  /// Effektives Segmentende: explizite [endTime], sonst Start des nächsten Punkts,
  /// sonst +45 Minuten (letzter Punkt ohne Ende).
  static DateTime scheduleEffectiveEnd(
    EventSchedule schedule, {
    EventSchedule? next,
  }) {
    if (schedule.endTime != null) {
      return AppDateTime.toLocal(schedule.endTime!);
    }
    if (next != null) {
      return AppDateTime.toLocal(next.startTime);
    }
    return AppDateTime.toLocal(schedule.startTime)
        .add(const Duration(minutes: 45));
  }

  static DateTime scheduleEffectiveEndAt(
    List<EventSchedule> schedules,
    int index,
  ) {
    final schedule = schedules[index];
    final next = index + 1 < schedules.length ? schedules[index + 1] : null;
    return scheduleEffectiveEnd(schedule, next: next);
  }

  static bool scheduleIsPast(
    EventSchedule schedule, {
    EventSchedule? next,
    DateTime? now,
  }) {
    return AppDateTime.isPastInstant(
      scheduleEffectiveEnd(schedule, next: next),
      now: now,
    );
  }

  static bool scheduleApplyPastStyling(
    EventSchedule schedule, {
    DateTime? now,
  }) {
    return AppDateTime.isTodayLocal(schedule.startTime, now: now);
  }

  /// Ob mindestens ein heutiger Ablaufpunkt bereits begonnen hat.
  static bool scheduleHasStarted(
    List<EventSchedule> schedules, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      if (!scheduleApplyPastStyling(schedule, now: now)) continue;
      final next = i + 1 < schedules.length ? schedules[i + 1] : null;
      if (scheduleIsPast(schedule, next: next, now: now)) return true;
      if (AppDateTime.toLocal(schedule.startTime).isBefore(clock)) return true;
    }
    return false;
  }

  /// Index des ersten sichtbaren, aktuellen Ablaufpunkts (heute, noch nicht beendet).
  ///
  /// `null`, wenn kein Jetzt-Anker gesetzt werden soll.
  static int? scheduleAnchorIndex(
    List<EventSchedule> schedules, {
    bool Function(EventSchedule schedule)? isVisible,
    DateTime? now,
  }) {
    for (var i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      if (isVisible != null && !isVisible(schedule)) continue;
      if (!scheduleApplyPastStyling(schedule, now: now)) continue;
      final next = i + 1 < schedules.length ? schedules[i + 1] : null;
      if (!scheduleIsPast(schedule, next: next, now: now)) return i;
    }
    return null;
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
