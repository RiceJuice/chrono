import 'dart:async';

import 'package:flutter/services.dart';

/// Einheitliche Haptik für Formulare, Picker und Aktionen (iOS-ähnlich).
abstract final class AppHaptics {
  static const Duration _pickerTickDebounce = Duration(milliseconds: 48);
  static const Duration _selectionDebounce = Duration(milliseconds: 280);

  static DateTime? _lastPickerTickAt;
  static DateTime? _lastSelectionAt;

  /// Leises Ticken bei Rad-/Scroll-Picker (debounced).
  static void pickerScrollTick() {
    final now = DateTime.now();
    final last = _lastPickerTickAt;
    if (last != null && now.difference(last) < _pickerTickDebounce) {
      return;
    }
    _lastPickerTickAt = now;
    unawaited(HapticFeedback.selectionClick());
  }

  /// Diskrete Auswahl (Datum-Tap, Chip, Dropdown-Eintrag).
  static void selection({bool playClickSound = true}) {
    final now = DateTime.now();
    final last = _lastSelectionAt;
    if (last != null && now.difference(last) < _selectionDebounce) {
      return;
    }
    _lastSelectionAt = now;
    unawaited(HapticFeedback.selectionClick());
    if (playClickSound) {
      _playClickSound();
    }
  }

  /// Auf-/Zuklappen von eingebetteten Pickern.
  static void expandToggle({required bool opening}) {
    if (opening) {
      unawaited(HapticFeedback.lightImpact());
    } else {
      selection(playClickSound: false);
    }
  }

  static void light() => unawaited(HapticFeedback.lightImpact());

  static void medium() => unawaited(HapticFeedback.mediumImpact());

  static Future<void> success() => HapticFeedback.successNotification();

  static Future<void> error() => HapticFeedback.errorNotification();

  static void _playClickSound() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Nicht auf allen Plattformen verfügbar; iOS-Cupertino-Rad hat eigenes Feedback.
    }
  }
}
