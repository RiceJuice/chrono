import 'package:chronoapp/features/calendar/presentation/providers/calendar_accent_overrides_provider.dart';
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
  const EventCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
    this.showInlineTimeRange,
    this.listTileHorizontalPadding,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hasChoir = entry.choir != BackendChoir.unknown;
                  final showTime = shouldShowCalendarEntryTimeRangeRow(
                    constraints: constraints,
                    wantTimeRange: wantTimeRange,
                    compact: true,
                    hasChoirLine: hasChoir,
                    hasDescription: false,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.choir != BackendChoir.unknown) ...[
                        Text(
                          entry.choir.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textHeightBehavior: _compactTextHeightBehavior,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: style.secondaryTextColor.withValues(
                              alpha: 0.75,
                            ),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        entry.eventName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textHeightBehavior: _compactTextHeightBehavior,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: style.primaryTextColor,
                          height: 1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (showTime) ...[
                        const SizedBox(height: 3),
                        CalendarEntryTimeRangeRow(
                          entry: entry,
                          mutedColor: style.secondaryTextColor.withValues(
                            alpha: 0.58,
                          ),
                          compact: true,
                        ),
                      ],
                    ],
                  );
                },
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
                                  if ((entry.description ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
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
                                      height: (entry.description ?? '')
                                              .trim()
                                              .isNotEmpty
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
                            SizedBox(
                              width: AppDimensions.eventCardImageWidth,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadiusGeometry.only(
                                          topRight: Radius.circular(AppRadius.s),
                                          bottomRight: Radius.circular(
                                            AppRadius.s,
                                          ),
                                        ),
                                    child: FutureBuilder<String?>(
                                      future: _firstImageUrlFuture,
                                      builder: (context, snapshot) {
                                        final url = snapshot.data;

                                        if (url == null &&
                                            snapshot.connectionState ==
                                                ConnectionState.done) {
                                          return Container(
                                            color: scheme.surfaceContainerHighest,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.broken_image),
                                          );
                                        }

                                        if (url == null) {
                                          return Container(
                                            color: scheme.surfaceContainerHighest,
                                          );
                                        }

                                        return CachedNetworkImage(
                                          imageUrl: url,
                                          cacheKey: _thumbnailCacheKey(entry),
                                          fit: BoxFit.cover,
                                          fadeInDuration: Duration.zero,
                                          fadeOutDuration: Duration.zero,
                                          placeholder: (context, _) => Container(
                                            color: scheme.surfaceContainerHighest,
                                          ),
                                          errorWidget: (context, _, error) {
                                            return Container(
                                              color: scheme.surfaceContainerHighest,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  if (style.imageOverlayOpacity > 0)
                                    Positioned.fill(
                                      child: ColoredBox(
                                        color: scheme.surface.withValues(
                                          alpha: style.imageOverlayOpacity,
                                        ),
                                      ),
                                    ),
                                ],
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
