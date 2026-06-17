import 'dart:async';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domspatzen_icon_metrics.dart';

/// Vorgerasterte PNG-Icons für den Kalender-Tab in der nativen iOS-Tab-Bar.
class IosCalendarTabIconSet {
  const IosCalendarTabIconSet({
    required this.inactive,
    required this.active,
    required this.brightness,
  });

  final Uint8List inactive;
  final Uint8List active;
  final Brightness brightness;
}

final iosCalendarTabIconsProvider =
    NotifierProvider<IosCalendarTabIconsNotifier, IosCalendarTabIconSet?>(
      IosCalendarTabIconsNotifier.new,
    );

class IosCalendarTabIconsNotifier extends Notifier<IosCalendarTabIconSet?> {
  static const _glyphSize = 17.0;
  static const _maxAttempts = 6;

  bool _loadInFlight = false;

  @override
  IosCalendarTabIconSet? build() => null;

  Future<void> ensureLoaded(BuildContext context) async {
    if (!_shouldLoadNativeTabIcons()) return;

    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final inactiveColor = scheme.onSurfaceVariant;
    final activeColor = scheme.primary;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    final cached = state;
    if (cached != null && cached.brightness == brightness) {
      return;
    }
    if (_loadInFlight) return;

    _loadInFlight = true;
    try {
      for (var attempt = 0; attempt < _maxAttempts; attempt++) {
        await DomspatzenIconMetrics.waitForGpuReady(attempt);

        final results = await Future.wait([
          DomspatzenIconMetrics.renderTabIconPngBytes(
            devicePixelRatio: devicePixelRatio,
            color: inactiveColor,
            glyphSize: _glyphSize,
          ),
          DomspatzenIconMetrics.renderTabIconPngBytes(
            devicePixelRatio: devicePixelRatio,
            color: activeColor,
            glyphSize: _glyphSize,
          ),
        ]);

        final inactiveBytes = results[0];
        final activeBytes = results[1];
        if (inactiveBytes != null && activeBytes != null) {
          state = IosCalendarTabIconSet(
            inactive: inactiveBytes,
            active: activeBytes,
            brightness: brightness,
          );
          return;
        }

        await Future<void>.delayed(
          Duration(milliseconds: 100 * (attempt + 1)),
        );
      }
    } finally {
      _loadInFlight = false;
    }
  }

  bool _shouldLoadNativeTabIcons() {
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }
}
