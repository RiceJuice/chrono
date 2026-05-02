import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const EventCard({
    super.key,
    required this.entry,
    this.applyPastStyling = false,
    this.showTimeColumn = true,
    this.weekGridCompact = false,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = widget.entry;
    final temporalState = CalendarEntryTemporalState.fromEntry(entry);
    final style = CalendarCardStyleResolver.resolve(
      context: context,
      baseBackgroundColor: scheme.secondary,
      temporalState: temporalState,
      applyPastStyling: widget.applyPastStyling,
    );
    final hasImageCandidate =
        (entry.imageUrls?.isNotEmpty ?? false) ||
        (entry.imagePaths?.isNotEmpty ?? false);

    if (widget.weekGridCompact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: () {
            HapticFeedback.heavyImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => BaseBottomModal(entry: widget.entry),
            );
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
                    wantTimeRange: !widget.showTimeColumn,
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

    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      minVerticalPadding: 0,
      dense: widget.weekGridCompact,
      visualDensity: widget.weekGridCompact ? VisualDensity.compact : null,
      onTap: () {
        HapticFeedback.heavyImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => BaseBottomModal(entry: widget.entry),
        );
      },
      contentPadding: EdgeInsets.only(
        left: widget.weekGridCompact ? AppSpacing.s : AppSpacing.l,
        right: widget.weekGridCompact ? AppSpacing.s : AppSpacing.l,
        bottom: widget.weekGridCompact ? 2 : 0,
      ),
      leading: widget.showTimeColumn
          ? TimeColumn(entry: entry, textColor: style.timeTextColor)
          : null,
      title: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          color: style.cardBackgroundColor,
        ),
        // IntrinsicHeight sorgt dafür, dass die Row so hoch ist wie ihr höchstes Kind
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // WICHTIG: Streckt Kinder auf die volle Höhe
            children: [
              Expanded(
                child: Padding(
                  padding: widget.weekGridCompact
                      ? AppInsets.eventCardContentCompact
                      : AppInsets.eventCardContent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.choir != BackendChoir.unknown) ...[
                        Text(
                          entry.choir.displayLabel,
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
                        textHeightBehavior: _compactTextHeightBehavior,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: style.primaryTextColor,
                          height: 1,
                          fontSize: widget.weekGridCompact ? 14 : 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!widget.weekGridCompact &&
                          (entry.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(
                          height: AppDimensions.eventCardDescriptionSpacing,
                        ),
                        Text(
                          entry.description!,
                          textHeightBehavior: _compactTextHeightBehavior,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: style.secondaryTextColor,
                            height: 1,
                          ),
                        ),
                      ],
                      if (!widget.showTimeColumn) ...[
                        SizedBox(
                          height: (entry.description ?? '').trim().isNotEmpty
                              ? 6
                              : 4,
                        ),
                        CalendarEntryTimeRangeRow(
                          entry: entry,
                          mutedColor: style.secondaryTextColor.withValues(
                            alpha: 0.58,
                          ),
                          compact: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasImageCandidate && !widget.weekGridCompact)
                SizedBox(
                  width: AppDimensions.eventCardImageWidth,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadiusGeometry.only(
                          topRight: Radius.circular(AppRadius.s),
                          bottomRight: Radius.circular(AppRadius.s),
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
                                  child: const Icon(Icons.broken_image),
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
    );
  }
}
