import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/calendar_entry_cached_image.dart';
import 'package:flutter/material.dart';

/// Bildstreifen für Essen-Karten: feste Breite, Höhe aus dem Bildseitenverhältnis.
class CalendarMealCardImageStrip extends StatefulWidget {
  const CalendarMealCardImageStrip({
    super.key,
    required this.entry,
    required this.placeholderColor,
    this.overlayColor,
  });

  final CalendarEntry entry;
  final Color placeholderColor;
  final Color? overlayColor;

  @override
  State<CalendarMealCardImageStrip> createState() =>
      _CalendarMealCardImageStripState();
}

class _CalendarMealCardImageStripState extends State<CalendarMealCardImageStrip> {
  double? _aspectRatio;

  static final BorderRadius _borderRadius = BorderRadius.only(
    topRight: Radius.circular(AppRadius.s),
    bottomRight: Radius.circular(AppRadius.s),
  );

  double _stripHeightForAspectRatio(double aspectRatio) {
    final width = AppDimensions.eventCardImageWidth;
    final naturalHeight = width / aspectRatio;
    return naturalHeight.clamp(
      AppDimensions.eventCardImageHeight,
      AppDimensions.mealCardImageMaxHeight,
    );
  }

  void _onAspectRatioResolved(double aspectRatio) {
    if (_aspectRatio == aspectRatio) return;
    setState(() => _aspectRatio = aspectRatio);
  }

  @override
  Widget build(BuildContext context) {
    final width = AppDimensions.eventCardImageWidth;
    final height = _aspectRatio != null
        ? _stripHeightForAspectRatio(_aspectRatio!)
        : AppDimensions.eventCardImageHeight;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CalendarEntryCachedImage(
              entry: widget.entry,
              placeholderColor: widget.placeholderColor,
              onAspectRatioResolved: _onAspectRatioResolved,
            ),
            if (widget.overlayColor != null)
              Positioned.fill(child: ColoredBox(color: widget.overlayColor!)),
          ],
        ),
      ),
    );
  }
}
