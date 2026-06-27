import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_key.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_manager.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_file_cache.dart';
import 'package:chronoapp/features/calendar/data/calendar_images.dart';
import 'package:chronoapp/features/calendar/data/calendar_signed_url_cache.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/calendar_local_disk_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum _ImageLoadPhase { loading, ready, failed }

/// Lädt das Event-Bild einmal und zeigt es danach aus dem lokalen Datei-Cache.
class CalendarEntryCachedImage extends StatefulWidget {
  const CalendarEntryCachedImage({
    super.key,
    required this.entry,
    this.imageIndex = 0,
    this.fit = BoxFit.cover,
    required this.placeholderColor,
    this.errorIconSize,
    this.onAspectRatioResolved,
  });

  final CalendarEntry entry;
  final int imageIndex;
  final BoxFit fit;
  final Color placeholderColor;
  final double? errorIconSize;

  /// Breite geteilt durch Höhe (`ImageInfo.width / ImageInfo.height`).
  final ValueChanged<double>? onAspectRatioResolved;

  @override
  State<CalendarEntryCachedImage> createState() => _CalendarEntryCachedImageState();
}

class _CalendarEntryCachedImageState extends State<CalendarEntryCachedImage> {
  _ImageLoadPhase _phase = _ImageLoadPhase.loading;
  Object? _localFile;
  String? _networkUrl;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant CalendarEntryCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.imageIndex != widget.imageIndex ||
        oldWidget.entry.imageUrls != widget.entry.imageUrls ||
        oldWidget.entry.imagePaths != widget.entry.imagePaths) {
      _phase = _ImageLoadPhase.loading;
      _localFile = null;
      _networkUrl = null;
      unawaited(_load());
    }
  }

  String get _cacheKey => calendarEventImageCacheKey(
    entryId: widget.entry.id,
    imageIndex: widget.imageIndex,
    entry: widget.entry,
  );

  Future<void> _load() async {
    final cacheKey = _cacheKey;

    final cachedFile = CalendarImageFileCache.peek(cacheKey);
    if (cachedFile != null) {
      _setReady(file: cachedFile);
      return;
    }

    final diskFile = await CalendarImageFileCache.resolve(cacheKey);
    if (!mounted) return;
    if (diskFile != null) {
      _setReady(file: diskFile);
      return;
    }

    await CalendarSignedUrlCache.shared.ensureLoaded();
    if (!mounted) return;

    final url = await _resolveUrl(widget.entry, widget.imageIndex);
    if (!mounted) return;
    if (url == null || url.isEmpty) {
      setState(() => _phase = _ImageLoadPhase.failed);
      return;
    }

    if (!kIsWeb) {
      try {
        final downloaded = await CalendarImageCacheManager.instance.downloadFile(
          url,
          key: cacheKey,
        );
        if (!mounted) return;
        CalendarImageFileCache.remember(cacheKey, downloaded.file);
        _setReady(file: downloaded.file);
        return;
      } catch (_) {
        if (!mounted) return;
      }
    }

    setState(() {
      _networkUrl = url;
      _phase = _ImageLoadPhase.ready;
    });
    _reportAspectRatio(
      CachedNetworkImageProvider(url, cacheKey: cacheKey),
    );
  }

  void _setReady({required Object file}) {
    setState(() {
      _localFile = file;
      _networkUrl = null;
      _phase = _ImageLoadPhase.ready;
    });
    _reportAspectRatio(resolveCalendarEntryDiskImageProvider(file));
  }

  void _reportAspectRatio(ImageProvider? provider) {
    final callback = widget.onAspectRatioResolved;
    if (callback == null || provider == null) return;

    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!mounted) return;
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (width > 0 && height > 0) {
          final ratio = width / height;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            callback(ratio);
          });
        }
      },
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  Future<String?> _resolveUrl(CalendarEntry entry, int index) async {
    final existingUrls = entry.imageUrls;
    if (existingUrls != null && existingUrls.length > index) {
      return existingUrls[index];
    }

    final imagePaths = entry.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) return null;

    final peeked = CalendarImages.urlResolver.peekResolvedUrls(imagePaths);
    if (peeked != null && peeked.length > index) return peeked[index];

    final resolved =
        await CalendarImages.urlResolver.resolveSignedUrls(imagePaths);
    if (resolved == null || resolved.length <= index) return null;
    return resolved[index];
  }

  @override
  Widget build(BuildContext context) {
    final errorIconSize = widget.errorIconSize ?? 24;
    final errorWidget = ColoredBox(
      color: widget.placeholderColor,
      child: Center(child: Icon(Icons.broken_image, size: errorIconSize)),
    );

    switch (_phase) {
      case _ImageLoadPhase.loading:
        return ColoredBox(color: widget.placeholderColor);
      case _ImageLoadPhase.failed:
        return errorWidget;
      case _ImageLoadPhase.ready:
        final file = _localFile;
        if (file != null) {
          return buildCalendarLocalDiskImage(
            file: file,
            fit: widget.fit,
            error: errorWidget,
          );
        }

        final url = _networkUrl;
        if (url == null) {
          return ColoredBox(color: widget.placeholderColor);
        }

        return CachedNetworkImage(
          imageUrl: url,
          cacheKey: _cacheKey,
          cacheManager: CalendarImageCacheManager.instance,
          fit: widget.fit,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, _) => ColoredBox(color: widget.placeholderColor),
          errorWidget: (context, _, _) => errorWidget,
        );
    }
  }
}
