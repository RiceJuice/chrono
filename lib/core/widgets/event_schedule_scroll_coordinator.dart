import 'package:flutter/foundation.dart';

/// Brücke für Nutzer-Scroll im Event-Sheet (z. B. Anker-Sprung abbrechen).
class EventScheduleScrollCoordinator {
  VoidCallback? onUserScroll;

  void notifyUserScroll() => onUserScroll?.call();
}
