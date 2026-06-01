import 'dart:ui' show ImageFilter;

import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/leading_indicator/calendar_card_leading_indicator.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class BaseCalendarCard extends StatelessWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final Color? backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  /// Akzentfarbe für den farbigen Streifen links; `null` = kein Streifen.
  final Color? leadingIndicatorColor;
  final bool showChoirAboveTitle;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool showTimeColumn;
  final bool weekGridCompact;

  /// Horizontaler Außenabstand der Zeile im Listen-Modus ([ListTile.contentPadding]).
  final double? listTileHorizontalPadding;

  /// Wenn `null`: wie bisher `!showTimeColumn`.
  final bool? showInlineTimeRange;

  /// Sheet-Header: Uhrzeiten nicht am Rand abschneiden.
  final bool modalHeaderPreview;

  /// 1 = volle Zeit-Spalte, 0 = eingeklappt (Inhalt wächst in den freien Platz).
  final double timeColumnCollapse;

  /// Wenn gesetzt: Backdrop-Blur nur auf der Kartenfläche (nicht Uhrzeit).
  final double? neighborGlassBlurSigma;

  /// Leichte Tönung über dem Blur (0 = nur Blur).
  final double? neighborGlassTintAlpha;

  const BaseCalendarCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.backgroundColor,
    this.contentPadding = CalendarCardLeadingIndicator.contentPadding,
    this.leadingIndicatorColor,
    this.showChoirAboveTitle = false,
    this.titleFontSize,
    this.titleFontWeight,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.listTileHorizontalPadding,
    this.showInlineTimeRange,
    this.modalHeaderPreview = false,
    this.timeColumnCollapse = 1,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: backgroundColor ?? scheme.surface,
      temporalState: temporalState,
      applyPastStyling: applyPastStyling,
    );

    final inlineTime = showInlineTimeRange ?? (!showTimeColumn);

    if (weekGridCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: AppSquircle.shape(AppRadius.s),
          onTap: () {
            HapticFeedback.heavyImpact();
            BaseBottomModal.show(context, entry: entry);
          },
          child: ClipSmoothRect(
            radius: AppSquircle.borderRadius(AppRadius.s),
            child: Ink(
              height: double.infinity,
              decoration: ShapeDecoration(
                color: style.cardBackgroundColor,
                shape: AppSquircle.shape(AppRadius.s),
              ),
              child: Padding(
                padding: contentPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (leadingIndicatorColor != null) ...[
                      CalendarCardLeadingIndicator(color: leadingIndicatorColor!),
                      const SizedBox(width: CalendarCardLeadingIndicator.gapAfterBar),
                    ],
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: CalendarCompactCardText(
                          entry: entry,
                          primaryTextColor: style.primaryTextColor,
                          secondaryTextColor: style.secondaryTextColor,
                          wantInlineTimeRange: inlineTime,
                          showChoirAboveTitle: showChoirAboveTitle,
                          titleFontSize: titleFontSize,
                          titleFontWeight: titleFontWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final rowHorizontalPadding =
        listTileHorizontalPadding ?? AppSpacing.l;

    void onCardTap() {
      HapticFeedback.heavyImpact();
      BaseBottomModal.show(context, entry: entry);
    }

    final collapse = timeColumnCollapse.clamp(0.0, 1.0);
    final timeColumnMorphing =
        modalHeaderPreview && showTimeColumn && collapse > 0 && collapse < 1;

    final row = Row(
      crossAxisAlignment: timeColumnMorphing
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (showTimeColumn && collapse > 0)
          Padding(
            padding: EdgeInsets.only(
              right: AppSpacing.s * collapse,
            ),
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: collapse,
                child: Opacity(
                  opacity: collapse,
                  child: TimeColumn(
                    entry: entry,
                    textColor: style.timeTextColor,
                    alignToContentHeight: !timeColumnMorphing,
                    suppressEdgeNudge: modalHeaderPreview,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: _buildCardBody(
            style: style,
            inlineTime: inlineTime,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rowHorizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          customBorder: AppSquircle.shape(AppRadius.s),
          child: timeColumnMorphing ? row : IntrinsicHeight(child: row),
        ),
      ),
    );
  }

  Widget _buildCardBody({
    required CalendarCardStyle style,
    required bool inlineTime,
  }) {
    Widget body = ClipSmoothRect(
      radius: AppSquircle.borderRadius(AppRadius.s),
      child: Container(
        decoration: ShapeDecoration(
          color: style.cardBackgroundColor,
          shape: AppSquircle.shape(AppRadius.s),
        ),
        child: Padding(
          padding: contentPadding,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leadingIndicatorColor != null) ...[
                  CalendarCardLeadingIndicator(color: leadingIndicatorColor!),
                  const SizedBox(
                    width: CalendarCardLeadingIndicator.gapAfterBar,
                  ),
                ],
                Expanded(
                  child: TextContent(
                    entry: entry,
                    primaryTextColor: style.primaryTextColor,
                    secondaryTextColor: style.secondaryTextColor,
                    showChoirAboveTitle: showChoirAboveTitle,
                    titleFontSize: titleFontSize,
                    titleFontWeight: titleFontWeight,
                    showInlineTimeRange: inlineTime,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final sigma = neighborGlassBlurSigma;
    if (sigma == null) return body;

    final tintAlpha = neighborGlassTintAlpha ?? 0;
    final tint = tintAlpha > 0
        ? Colors.white.withValues(alpha: tintAlpha)
        : Colors.transparent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          body,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: ColoredBox(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}
