import 'dart:math' as math;

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/theme/calendar_presentation_theme.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_card_style_resolver.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_card.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/calendar_entry_temporal_state.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flächenfarbe der Karte in der Modal-Header-Vorschau (nicht immer = Akzent).
Color modalPreviewCardFillColor(
  BuildContext context,
  WidgetRef ref,
  CalendarEntry entry,
) {
  final accent = resolveCalendarEntryAccent(ref, entry);
  return switch (entry.type) {
    CalendarEntryType.lesson => CalendarPresentationTheme.lessonCardBackgroundColor(
      context,
      accent,
    ),
    CalendarEntryType.choir => Theme.of(context).colorScheme.primary,
    CalendarEntryType.meal || CalendarEntryType.event => accent,
    CalendarEntryType.breakType => accent,
  };
}

/// Unterhalb dieses Kontrastverhältnisses (WCAG-Luminanz) hebt ein stärkerer,
/// neutraler Schatten die Karte vom Header ab.
const double _kModalPreviewMinContrastForElevation = 2.0;

double _relativeLuminance(Color color) {
  double channel(double c) {
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

bool _modalPreviewCardNeedsLowContrastLift(
  Color headerAccentColor,
  Color cardFillColor,
) {
  return _contrastRatio(headerAccentColor, cardFillColor) <
      _kModalPreviewMinContrastForElevation;
}

List<BoxShadow> modalPreviewCardBoxShadows({
  required Color headerAccentColor,
  required Color cardFillColor,
}) {
  final needsLift = _modalPreviewCardNeedsLowContrastLift(
    headerAccentColor,
    cardFillColor,
  );
  if (needsLift) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 22,
        spreadRadius: 0,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 6,
        spreadRadius: 0.5,
        offset: const Offset(0, 2),
      ),
    ];
  }
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: headerAccentColor.withValues(alpha: 0.5),
      blurRadius: 28,
      spreadRadius: -4,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Zeile im Sheet-Header: Uhrzeit frei stehend, Schatten nur um die Karte.
class ModalPreviewHeaderEntryRow extends ConsumerWidget {
  const ModalPreviewHeaderEntryRow({
    super.key,
    required this.entry,
    required this.headerAccentColor,
    this.applyPastStyling = false,
    this.listTileHorizontalPadding = AppSpacing.s,
    this.cardContentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.m,
      vertical: AppSpacing.l,
    ),
    this.cardTitleFontSize = 17.5,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  final CalendarEntry entry;
  final Color headerAccentColor;
  final bool applyPastStyling;
  final double listTileHorizontalPadding;
  final EdgeInsetsGeometry cardContentPadding;
  final double cardTitleFontSize;
  final double? neighborGlassBlurSigma;
  final double? neighborGlassTintAlpha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final cardFill = modalPreviewCardFillColor(context, ref, entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: cardFill,
      temporalState: temporalState,
      applyPastStyling: applyPastStyling,
    );
    final contentInsets = cardContentPadding.resolve(
      Directionality.of(context),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: listTileHorizontalPadding),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: contentInsets.top,
                bottom: contentInsets.bottom,
                right: AppSpacing.s,
              ),
              child: TimeColumn(
                entry: entry,
                textColor: style.timeTextColor,
                alignToContentHeight: true,
                suppressEdgeNudge: true,
              ),
            ),
            Expanded(
              child: ModalPreviewCardChrome(
                entry: entry,
                headerAccentColor: headerAccentColor,
                scale: 1,
                child: CalendarEntryCard(
                  entry: entry,
                  applyPastStyling: applyPastStyling,
                  showTimeColumn: false,
                  showInlineTimeRange: false,
                  listTileHorizontalPadding: 0,
                  cardContentPadding: cardContentPadding,
                  cardTitleFontSize: cardTitleFontSize,
                  modalHeaderPreview: true,
                  neighborGlassBlurSigma: neighborGlassBlurSigma,
                  neighborGlassTintAlpha: neighborGlassTintAlpha,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Schatten um die Termin-Kartenfläche (nicht die Uhrzeit).
class ModalPreviewCardChrome extends ConsumerWidget {
  const ModalPreviewCardChrome({
    super.key,
    required this.entry,
    required this.headerAccentColor,
    required this.child,
    this.scale = 1.02,
  });

  final CalendarEntry entry;
  final Color headerAccentColor;
  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardFill = modalPreviewCardFillColor(context, ref, entry);
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          boxShadow: modalPreviewCardBoxShadows(
            headerAccentColor: headerAccentColor,
            cardFillColor: cardFill,
          ),
        ),
        child: child,
      ),
    );
  }
}
