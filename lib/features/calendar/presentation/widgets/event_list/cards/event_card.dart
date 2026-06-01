import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/calendar_card_image_strip.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import '../../../../data/calendar_image_url_resolver.dart';
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

  static final CalendarImageUrlResolver _imageUrlResolver =
      CalendarImageUrlResolver(supabase: Supabase.instance.client);
  late Future<String?> _firstImageUrlFuture;

  @override
  void initState() {
    super.initState();
    _firstImageUrlFuture = _resolveFirstImageUrl(widget.entry);
  }

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        !listEquals(oldWidget.entry.imageUrls, widget.entry.imageUrls) ||
        !listEquals(oldWidget.entry.imagePaths, widget.entry.imagePaths)) {
      _firstImageUrlFuture = _resolveFirstImageUrl(widget.entry);
    }
  }

  Future<String?> _resolveFirstImageUrl(CalendarEntry entry) async {
    final existingUrls = entry.imageUrls;
    if (existingUrls != null && existingUrls.isNotEmpty) {
      return existingUrls.first;
    }
    final imagePaths = entry.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) return null;
    final resolvedUrls = await _imageUrlResolver.resolveSignedUrls(imagePaths);
    if (resolvedUrls == null || resolvedUrls.isEmpty) return null;
    return resolvedUrls.first;
  }

  String _thumbnailCacheKey(CalendarEntry entry) {
    final sourceKey = (entry.imagePaths != null && entry.imagePaths!.isNotEmpty)
        ? entry.imagePaths!.first
        : (entry.imageUrls != null && entry.imageUrls!.isNotEmpty)
        ? entry.imageUrls!.first
        : 'no-image';
    return 'calendar-thumb-${entry.id}-$sourceKey';
  }

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
                              image: FutureBuilder<String?>(
                                future: _firstImageUrlFuture,
                                builder: (context, snapshot) {
                                  final url = snapshot.data;

                                  if (url == null &&
                                      snapshot.connectionState ==
                                          ConnectionState.done) {
                                    return ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    );
                                  }

                                  if (url == null) {
                                    return ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                    );
                                  }

                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    cacheKey: _thumbnailCacheKey(entry),
                                    fit: BoxFit.cover,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholder: (context, _) => ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                    ),
                                    errorWidget: (context, _, error) {
                                      return ColoredBox(
                                        color: scheme.surfaceContainerHighest,
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  );
                                },
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
