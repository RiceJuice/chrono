import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_key.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_manager.dart';
import 'package:chronoapp/features/calendar/data/calendar_images.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart'
    show BottomModalHandle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Layout der Bildleiste im Detail-Sheet.
enum BottomModalImagesLayout {
  /// Mehrere Bilder horizontal scrollbar.
  carousel,

  /// Ein Bild über die volle Breite (z. B. Essen).
  single,
}

class BottomModalImages extends StatefulWidget {
  final CalendarEntry entry;
  final BottomModalImagesLayout layout;
  final bool clipTopCorners;
  final bool showHandle;

  const BottomModalImages({
    super.key,
    required this.entry,
    this.layout = BottomModalImagesLayout.carousel,
    this.clipTopCorners = false,
    this.showHandle = false,
  });

  @override
  State<BottomModalImages> createState() => _BottomModalImagesState();
}

const double _kModalDetailPanelHeight = 200;

/// Abstand zwischen nebeneinander liegenden Bildern im Karussell.
const double _kModalDetailImageGap = AppSpacing.xs;

BorderRadius _modalDetailImageBorderRadius({
  required int index,
  required int count,
}) {
  final radius = Radius.circular(AppRadius.s);
  return BorderRadius.only(
    topLeft: index == 0 ? radius : Radius.zero,
    topRight: index == count - 1 ? radius : Radius.zero,
  );
}

int _knownImageCount(CalendarEntry entry) {
  final urls = entry.imageUrls;
  if (urls != null && urls.isNotEmpty) return urls.length;
  final paths = entry.imagePaths;
  if (paths != null && paths.isNotEmpty) return paths.length;
  return 0;
}

class _BottomModalImagesState extends State<BottomModalImages> {
  List<String>? _immediateImageUrls;
  Future<List<String>>? _imageUrlsFuture;

  bool get _singleLayout => widget.layout == BottomModalImagesLayout.single;

  @override
  void initState() {
    super.initState();
    _syncImageUrls();
  }

  @override
  void didUpdateWidget(covariant BottomModalImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        !listEquals(oldWidget.entry.imageUrls, widget.entry.imageUrls) ||
        !listEquals(oldWidget.entry.imagePaths, widget.entry.imagePaths)) {
      _syncImageUrls();
    }
  }

  void _syncImageUrls() {
    final entry = widget.entry;
    final existingUrls = entry.imageUrls;
    if (existingUrls != null && existingUrls.isNotEmpty) {
      _immediateImageUrls = existingUrls;
      _imageUrlsFuture = null;
      return;
    }

    final imagePaths = entry.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) {
      _immediateImageUrls = const <String>[];
      _imageUrlsFuture = null;
      return;
    }

    final peeked = CalendarImages.urlResolver.peekResolvedUrls(imagePaths);
    if (peeked != null) {
      _immediateImageUrls = peeked;
      _imageUrlsFuture = null;
      return;
    }

    _immediateImageUrls = null;
    _imageUrlsFuture = _resolveImageUrls(entry);
  }

  Future<List<String>> _resolveImageUrls(CalendarEntry entry) async {
    final existingUrls = entry.imageUrls;
    if (existingUrls != null && existingUrls.isNotEmpty) return existingUrls;

    final imagePaths = entry.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) return const <String>[];
    return await CalendarImages.urlResolver.resolveSignedUrls(imagePaths) ??
        const <String>[];
  }

  int _carouselLoadingPlaceholderCount() {
    final known = _knownImageCount(widget.entry);
    if (known > 0) return known;
    return 2;
  }

  Widget _buildCarouselContent({
    required bool isLoading,
    required bool hasError,
    required List<String> imageUrls,
    required Color imagePanelBg,
  }) {
    if (isLoading) {
      final itemCount = _carouselLoadingPlaceholderCount();
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < itemCount - 1 ? _kModalDetailImageGap : 0,
            ),
            child: ClipRRect(
              borderRadius: _modalDetailImageBorderRadius(
                index: index,
                count: itemCount,
              ),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: imagePanelBg),
                ),
              ),
            ),
          );
        },
      );
    }
    if (hasError) {
      return _NoImageState(
        icon: Icons.error_outline,
        text: 'Bilder konnten nicht geladen werden.',
      );
    }
    if (imageUrls.isEmpty) {
      return const _NoImageState(
        icon: Icons.image_not_supported_outlined,
        text: 'Keine Bilder vorhanden.',
      );
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        final count = imageUrls.length;
        return Padding(
          padding: EdgeInsets.only(
            right: index < count - 1 ? _kModalDetailImageGap : 0,
          ),
          child: ClipRRect(
            borderRadius: _modalDetailImageBorderRadius(
              index: index,
              count: count,
            ),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                cacheKey: calendarEventImageCacheKey(
                  entryId: widget.entry.id,
                  imageIndex: index,
                  entry: widget.entry,
                ),
                cacheManager: CalendarImageCacheManager.instance,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, _) => ColoredBox(color: imagePanelBg),
                errorWidget: (context, _, _) => ColoredBox(
                  color: imagePanelBg,
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleImageContent({
    required bool isLoading,
    required bool hasError,
    required List<String> imageUrls,
    required Color imagePanelBg,
  }) {
    if (isLoading) {
      return _ModalSingleImageFrame(
        backgroundColor: imagePanelBg,
        child: ColoredBox(color: imagePanelBg),
      );
    }
    if (hasError) {
      return _ModalSingleImageFrame(
        backgroundColor: imagePanelBg,
        child: _NoImageState(
          icon: Icons.error_outline,
          text: 'Bild konnte nicht geladen werden.',
        ),
      );
    }
    if (imageUrls.isEmpty) {
      return _ModalSingleImageFrame(
        backgroundColor: imagePanelBg,
        child: const _NoImageState(
          icon: Icons.image_not_supported_outlined,
          text: 'Kein Bild vorhanden.',
        ),
      );
    }
    final imageUrl = imageUrls.first;
    return _ModalSingleImageFrame(
      backgroundColor: imagePanelBg,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheKey: calendarEventImageCacheKey(
          entryId: widget.entry.id,
          imageIndex: 0,
          entry: widget.entry,
        ),
        cacheManager: CalendarImageCacheManager.instance,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, _) => ColoredBox(color: imagePanelBg),
        errorWidget: (context, _, _) => ColoredBox(
          color: imagePanelBg,
          child: const Icon(Icons.broken_image, size: 50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePanelBg = Theme.of(context).colorScheme.surface;
    final immediateUrls = _immediateImageUrls;
    if (immediateUrls != null) {
      return _buildPanel(
        imagePanelBg: imagePanelBg,
        isLoading: false,
        hasError: false,
        imageUrls: immediateUrls,
      );
    }

    return FutureBuilder<List<String>>(
      future: _imageUrlsFuture,
      builder: (context, snapshot) {
        return _buildPanel(
          imagePanelBg: imagePanelBg,
          isLoading: snapshot.connectionState != ConnectionState.done,
          hasError: snapshot.hasError,
          imageUrls: snapshot.data ?? const <String>[],
        );
      },
    );
  }

  Widget _buildPanel({
    required Color imagePanelBg,
    required bool isLoading,
    required bool hasError,
    required List<String> imageUrls,
  }) {
    final content = _singleLayout
        ? _buildSingleImageContent(
            isLoading: isLoading,
            hasError: hasError,
            imageUrls: imageUrls,
            imagePanelBg: imagePanelBg,
          )
        : _buildCarouselContent(
            isLoading: isLoading,
            hasError: hasError,
            imageUrls: imageUrls,
            imagePanelBg: imagePanelBg,
          );

    final panel = Stack(
      children: [
        SizedBox(
          height: _kModalDetailPanelHeight,
          width: double.infinity,
          child: ColoredBox(color: imagePanelBg, child: content),
        ),
        if (widget.showHandle) const BottomModalHandle(),
      ],
    );

    return widget.clipTopCorners
        ? ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            child: panel,
          )
        : panel;
  }
}

/// Volle Breite der Bildleiste, obere Ecken wie die Sheet-Karte.
class _ModalSingleImageFrame extends StatelessWidget {
  const _ModalSingleImageFrame({
    required this.backgroundColor,
    required this.child,
  });

  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.s),
      ),
      child: SizedBox(
        width: double.infinity,
        height: _kModalDetailPanelHeight,
        child: ColoredBox(
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }
}

class _NoImageState extends StatelessWidget {
  const _NoImageState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
