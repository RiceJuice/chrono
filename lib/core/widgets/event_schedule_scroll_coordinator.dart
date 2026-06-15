import 'package:flutter/foundation.dart';

/// Brücke für Nutzer-Scroll im Event-Sheet (z. B. Anker-Sprung abbrechen).
class EventScheduleScrollCoordinator {
  VoidCallback? onUserScroll;

  bool _anchorScrollViewportReady = true;
  VoidCallback? _pendingAnchorScroll;

  /// Verzögert den initialen Anker-Sprung, bis das Sheet voll expandiert ist.
  void requireExpandedViewportForAnchorScroll() {
    _anchorScrollViewportReady = false;
  }

  void markAnchorScrollViewportReady() {
    if (_anchorScrollViewportReady) return;
    _anchorScrollViewportReady = true;
    _pendingAnchorScroll?.call();
    _pendingAnchorScroll = null;
  }

  void runWhenAnchorScrollViewportReady(VoidCallback action) {
    if (_anchorScrollViewportReady) {
      action();
      return;
    }
    _pendingAnchorScroll = action;
  }

  void notifyUserScroll() => onUserScroll?.call();
}
