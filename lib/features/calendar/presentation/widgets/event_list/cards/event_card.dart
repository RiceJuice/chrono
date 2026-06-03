import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/calendar_card_image_strip.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/calendar_entry_cached_image.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import '../../../../domain/models/calendar_entry.dart';
import 'calendar_card_style_resolver.dart';
import 'calendar_entry_temporal_state.dart';

class EventCard extends StatefulWidget {
  final CalendarEntry entry;
  final bool applyPastStyling;
  final bool showTimeColumn;
  final bool weekGridCompact;
  final bool? showInlineTimeRange;
  final double? listTileHorizontalPadding;
  final bool modalHeaderPreview;
  final double? neighborGlassBlurSigma;
  final double? neighborGlassTintAlpha;

  const EventCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
    this.modalHeaderPreview = false,
    this.neighborGlassBlurSigma,
    this.neighborGlassTintAlpha,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  static const _compactTextHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        final entry = widget.entry;
        final temporalState = CalendarEntryTemporalState.fromEntry(entry);
        final accent = resolveCalendarEntryAccent(ref, entry);
        final style = CalendarCardStyleResolver.resolve(
          context: context,
          baseBackgroundColor: accent,
          temporalState: temporalState,
          applyPastStyling: widget.applyPastStyling,
        );
        return _buildCard(context, theme, entry, style);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    CalendarEntry entry,
    CalendarCardStyle style,
  ) {
    final scheme = theme.colorScheme;
    final hasImageCandidate =
        (entry.imageUrls?.isNotEmpty ?? false) ||
        (entry.imagePaths?.isNotEmpty ?? false);
    final wantTimeRange =
        widget.showInlineTimeRange ?? !widget.showTimeColumn;
    final trimmedLocation = (entry.location ?? '').trim();
    final hasDescription = (entry.description ?? '').trim().isNotEmpty;

    if (widget.weekGridCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: () {
            HapticFeedback.heavyImpact();
            BaseBottomModal.show(context, entry: widget.entry);
          },
          child: Ink(
            height: double.infinity,
            padding: AppInsets.eventCardContentCompact,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              color: style.cardBackgroundColor,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: CalendarCompactCardText(
                entry: entry,
                primaryTextColor: style.primaryTextColor,
                secondaryTextColor: style.secondaryTextColor,
                wantInlineTimeRange: wantTimeRange,
                showChoirAboveTitle: true,
                titleFontSize: 14,
                titleFontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final rowHorizontalPadding =
        widget.listTileHorizontalPadding ?? AppSpacing.l;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rowHorizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            BaseBottomModal.show(context, entry: widget.entry);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showTimeColumn)
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppInsets.eventCardContent.top,
                      bottom: AppInsets.eventCardContent.bottom,
                      right: AppSpacing.s,
                    ),
                    child: TimeColumn(
                      entry: entry,
                      textColor: style.timeTextColor,
                      alignToContentHeight: true,
                      suppressEdgeNudge: widget.modalHeaderPreview,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.s),
                      color: style.cardBackgroundColor,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: AppInsets.eventCardContent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.choir != BackendChoir.unknown) ...[
                                    Text(
                                      entry.choir.displayLabel,
                                      textHeightBehavior:
                                          _compactTextHeightBehavior,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: style.secondaryTextColor
                                                .withValues(alpha: 0.75),
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    entry.eventName,
                                    textHeightBehavior:
                                        _compactTextHeightBehavior,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: style.primaryTextColor,
                                          height: 1,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  if (trimmedLocation.isNotEmpty) ...[
                                    const SizedBox(
                                      height:
                                          AppDimensions.eventCardDescriptionSpacing,
                                    ),
                                    CalendarEntryLocationRow(
                                      location: trimmedLocation,
                                      subtitleColor: style.secondaryTextColor,
                                      mutedColor: style.secondaryTextColor
                                          .withValues(alpha: 0.58),
                                    ),
                                  ] else if (hasDescription) ...[
                                    const SizedBox(
                                      height:
                                          AppDimensions.eventCardDescriptionSpacing,
                                    ),
                                    Text(
                                      entry.description!,
                                      textHeightBehavior:
                                          _compactTextHeightBehavior,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: style.secondaryTextColor,
                                            height: 1,
                                          ),
                                    ),
                                  ],
                                  if (wantTimeRange) ...[
                                    SizedBox(
                                      height: trimmedLocation.isNotEmpty ||
                                              hasDescription
                                          ? 6
                                          : 4,
                                    ),
                                    CalendarEntryTimeRangeRow(
                                      entry: entry,
                                      mutedColor: style.secondaryTextColor
                                          .withValues(alpha: 0.58),
                                      compact: false,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (hasImageCandidate)
                            CalendarCardImageStrip(
                              overlayColor: style.imageOverlayOpacity > 0
                                  ? scheme.surface.withValues(
                                      alpha: style.imageOverlayOpacity,
                                    )
                                  : null,
                              image: CalendarEntryCachedImage(
                                entry: entry,
                                placeholderColor:
                                    scheme.surfaceContainerHighest,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
