import 'dart:io' show Platform;
import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';

/// Kurve für weichen Blur-Verlauf (oben stark → unten transparent).
const Curve kCalendarProgressiveBlurCurve = Curves.easeOutCubic;

/// Stützpunkte der Verlaufskarte — mehr = durchgängiger (Shader, kein Slice-Stapel).
const int kCalendarProgressiveBlurStopCount = 16;

/// Weicher Top-Blur fürs Event-Sheet — volle Streifen-Höhe, langer Ausklang.
///
/// Kein [extent]-Cutoff (der erzeugt einen sichtbaren Kanten-Sprung).
InspireBlurConfig calendarEventSheetTopBlurConfig({required double sigma}) {
  return InspireBlurConfig(
    sigma: sigma,
    start: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [
      0.00,
      0.08,
      0.18,
      0.30,
      0.44,
      0.58,
      0.72,
      0.84,
      0.93,
      1.00,
    ],
    values: const [
      1.00,
      0.97,
      0.90,
      0.78,
      0.62,
      0.44,
      0.28,
      0.14,
      0.05,
      0.00,
    ],
  );
}

/// Erzeugt eine [InspireBlurConfig] mit feinerem Verlauf als die Package-Defaults.
InspireBlurConfig calendarProgressiveTopBlurConfig({
  required double sigma,
  Curve fadeCurve = kCalendarProgressiveBlurCurve,
  double extent = 1.0,
  int stopCount = kCalendarProgressiveBlurStopCount,
}) {
  final points = _curveToBlurStops(
    extent: extent,
    curve: fadeCurve,
    stopsCount: stopCount,
  );
  return InspireBlurConfig(
    sigma: sigma,
    start: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: points.map((e) => e.$1).toList(),
    values: points.map((e) => e.$2).toList(),
  );
}

List<(double, double)> _curveToBlurStops({
  required double extent,
  required Curve curve,
  required int stopsCount,
}) {
  assert(extent >= 0.0 && extent <= 1.0);
  assert(stopsCount >= 2);

  if (extent == 0.0) {
    return [(0.0, curve.transform(1.0)), (1.0, curve.transform(0.0))];
  }

  return List.generate(stopsCount, (i) {
    final t = i / (stopsCount - 1);
    final stop = t * extent;
    final value = curve.transform(1 - t).clamp(0.0, 1.0);
    return (stop, value);
  });
}

/// Progressiver Backdrop-Blur (Inhalt *unter* dem Widget, z. B. Stack-Overlay).
///
/// Nutzt einen GPU-Shader mit Verlaufskarte (1 H + 1 V Pass) statt vieler
/// gestapelter [BackdropFilter]-Slices.
class CalendarProgressiveBackdropBlur extends StatelessWidget {
  const CalendarProgressiveBackdropBlur({
    super.key,
    this.maxSigma = 0,
    this.config,
    required this.child,
    this.fadeCurve = kCalendarProgressiveBlurCurve,
    this.extent = 1.0,
    this.clipBehavior = Clip.antiAlias,
    /// Bei scrollendem Hintergrund `false`, damit der Blur aktuell bleibt.
    this.useRepaintBoundary = false,
  }) : assert(config != null || maxSigma > 0);

  final double maxSigma;
  final InspireBlurConfig? config;
  final Widget child;
  final Curve fadeCurve;
  final double extent;
  final Clip clipBehavior;
  final bool useRepaintBoundary;

  InspireBlurConfig get _resolvedConfig =>
      config ??
      calendarProgressiveTopBlurConfig(
        sigma: maxSigma,
        fadeCurve: fadeCurve,
        extent: extent,
      );

  double get _resolvedSigma => config?.sigma ?? maxSigma;

  @override
  Widget build(BuildContext context) {
    if (_resolvedSigma <= 0) return child;

    // Impeller-Shader-Blur rendert auf manchen Android-Geräten/Emulatoren schwarz.
    final useShaderBlur = ui.ImageFilter.isShaderFilterSupported &&
        !(Platform.isAndroid && !kIsWeb);
    if (!useShaderBlur) {
      return _CalendarProgressiveBackdropBlurFallback(
        maxSigma: _resolvedSigma,
        fadeCurve: fadeCurve,
        extent: config != null ? 1.0 : extent,
        child: child,
      );
    }

    return Inspire.backdropBlur(
      config: _resolvedConfig,
      clipBehavior: clipBehavior,
      useRepaintBoundary: useRepaintBoundary,
      child: child,
    );
  }
}

/// Fallback ohne Impeller-Shader: wenige gebündelte Backdrop-Pässe.
class _CalendarProgressiveBackdropBlurFallback extends StatelessWidget {
  const _CalendarProgressiveBackdropBlurFallback({
    required this.maxSigma,
    required this.fadeCurve,
    required this.extent,
    required this.child,
  });

  final double maxSigma;
  final Curve fadeCurve;
  final double extent;
  final Widget child;

  static const int _bands = 8;

  @override
  Widget build(BuildContext context) {
    final blurFlex = (extent.clamp(0.0, 1.0) * 100).round().clamp(1, 100);
    final clearFlex = 100 - blurFlex;

    return ClipRect(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            children: [
              Expanded(
                flex: blurFlex,
                child: BackdropGroup(
                  child: Column(
                    children: [
                      for (var i = 0; i < _bands; i++)
                        Expanded(
                          child: _bandSigma(i) > 0.02
                              ? BackdropFilter.grouped(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: _bandSigma(i),
                                    sigmaY: _bandSigma(i),
                                  ),
                                  child: const ColoredBox(
                                    color: Color(0x01FFFFFF),
                                    child: SizedBox.expand(),
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                    ],
                  ),
                ),
              ),
              if (clearFlex > 0)
                Expanded(
                  flex: clearFlex,
                  child: const SizedBox.expand(),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  double _bandSigma(int bandIndex) {
    final t = bandIndex / (_bands - 1);
    return maxSigma * fadeCurve.transform(1 - t);
  }
}
