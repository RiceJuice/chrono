import 'dart:async';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'domspatzen_icon_metrics.dart';
import 'ios_calendar_tab_icons_provider.dart';

/// Domspatzen-SVG mit Theme-Farbe; auf iOS 26+ optional vorgerastertes PNG.
class DomspatzenIcon extends ConsumerStatefulWidget {
  const DomspatzenIcon({
    required this.glyphSize,
    required this.color,
    this.preferRasterized = true,
    super.key,
  });

  final double glyphSize;
  final Color color;

  /// Auf iOS mit Native Glass PNG statt SvgPicture bevorzugen.
  final bool preferRasterized;

  @override
  ConsumerState<DomspatzenIcon> createState() => _DomspatzenIconState();
}

class _DomspatzenIconState extends ConsumerState<DomspatzenIcon> {
  static const _maxRasterAttempts = 3;

  Uint8List? _rasterBytes;
  bool _rasterLoadInFlight = false;

  bool get _shouldPreferRaster {
    if (!widget.preferRasterized) return false;
    return defaultTargetPlatform == TargetPlatform.iOS &&
        PlatformVersion.shouldUseNativeGlass;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRasterSource();
  }

  @override
  void didUpdateWidget(DomspatzenIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glyphSize != widget.glyphSize ||
        oldWidget.color != widget.color ||
        oldWidget.preferRasterized != widget.preferRasterized) {
      _rasterBytes = null;
      _rasterLoadInFlight = false;
      _syncRasterSource();
    }
  }

  void _syncRasterSource() {
    if (!_shouldPreferRaster) {
      _rasterBytes = null;
      return;
    }

    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final tabIcons = ref.read(iosCalendarTabIconsProvider);

    if (widget.color == scheme.onSurfaceVariant &&
        tabIcons != null &&
        tabIcons.brightness == brightness) {
      if (!identical(_rasterBytes, tabIcons.inactive)) {
        setState(() => _rasterBytes = tabIcons.inactive);
      }
      return;
    }

    if (_rasterBytes != null || _rasterLoadInFlight) return;
    _rasterLoadInFlight = true;
    unawaited(_loadRasterBytes());
  }

  Future<void> _loadRasterBytes() async {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final color = widget.color;
    final glyphSize = widget.glyphSize;

    try {
      for (var attempt = 0; attempt < _maxRasterAttempts; attempt++) {
        await DomspatzenIconMetrics.waitForGpuReady(attempt);

        if (!mounted) return;

        final bytes = await DomspatzenIconMetrics.renderTabIconPngBytes(
          devicePixelRatio: devicePixelRatio,
          color: color,
          glyphSize: glyphSize,
        );

        if (!mounted) return;
        if (bytes != null) {
          setState(() => _rasterBytes = bytes);
          return;
        }

        await Future<void>.delayed(
          Duration(milliseconds: 100 * (attempt + 1)),
        );
      }
    } finally {
      if (mounted) {
        _rasterLoadInFlight = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(iosCalendarTabIconsProvider)
      ..listen<IosCalendarTabIconSet?>(iosCalendarTabIconsProvider, (_, _) {
        _syncRasterSource();
      });

    final assetSize = DomspatzenIconMetrics.assetSizeForGlyph(widget.glyphSize);
    final rasterBytes = _shouldPreferRaster ? _rasterBytes : null;

    if (rasterBytes != null) {
      return Image.memory(
        rasterBytes,
        width: assetSize,
        height: assetSize,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    return SvgPicture.asset(
      DomspatzenIconMetrics.assetPath,
      width: assetSize,
      height: assetSize,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
    );
  }
}
