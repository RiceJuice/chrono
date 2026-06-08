import 'package:cached_network_image/cached_network_image.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_key.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_cache_manager.dart';
import 'package:chronoapp/features/calendar/data/calendar_images.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart'
    show BottomModalHandle;
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/skeleton_loader.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Äußerer Radius der umgebenden Fläche (z. B. [AppRadius.sheet] vom Modal).
  /// Wird mit dem Karussell-Padding zum inneren Clip-Radius umgerechnet.
  final double? imageOuterBorderRadius;

  const BottomModalImages({
    super.key,
    required this.entry,
    this.layout = BottomModalImagesLayout.carousel,
    this.clipTopCorners = false,
    this.showHandle = false,
    this.imageOuterBorderRadius,
  });

  @override
  State<BottomModalImages> createState() => _BottomModalImagesState();
}

const double _kModalDetailPanelHeight = 260;

/// Virtueller Start für endloses Scrollen (wie Chor-Karussell).
const int _kCarouselInitialPageOffset = 10000;


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
  PageController? _pageController;
  double? _viewportFraction;

  bool get _singleLayout => widget.layout == BottomModalImagesLayout.single;

  double get _imageGap => _horizontalInset;

  double get _horizontalInset => widget.imageOuterBorderRadius != null
      ? EventBottomModalTypography.imageHeaderSpacing
      : AppSpacing.xs;

  double get _verticalInset => widget.imageOuterBorderRadius != null
      ? EventBottomModalTypography.imageHeaderSpacing
      : 0;

  double _carouselContentHeight() =>
      _kModalDetailPanelHeight - _verticalInset * 2;

  /// Volle Bildbreite zwischen den Seitenrändern.
  double _carouselImageWidth(double viewportWidth) =>
      viewportWidth - _horizontalInset * 2;

  /// Eine Seite = Seiten-Padding + Bild + kleiner Zwischenraum.
  double _carouselPageExtent(double viewportWidth) =>
      _horizontalInset + _carouselImageWidth(viewportWidth) + _imageGap;

  int _initialVirtualPage(int itemCount) {
    if (itemCount <= 0) return 0;
    return _kCarouselInitialPageOffset -
        (_kCarouselInitialPageOffset % itemCount);
  }

  int _imageIndexForPage(int page, int itemCount) {
    if (itemCount <= 0) return 0;
    return (page % itemCount + itemCount) % itemCount;
  }

  int _pageForImageIndex(int imageIndex, int itemCount) =>
      _initialVirtualPage(itemCount) + imageIndex;

  void _onCarouselPageChanged(int index, int itemCount) {
    HapticFeedback.mediumImpact();

    final controller = _pageController;
    if (controller == null || itemCount <= 1) return;

    const lowThreshold = 1000;
    const highThreshold = _kCarouselInitialPageOffset + 1000;
    if (index < lowThreshold || index > highThreshold) {
      final imageIndex = _imageIndexForPage(index, itemCount);
      final targetPage = _pageForImageIndex(imageIndex, itemCount);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (controller.hasClients) {
          controller.jumpToPage(targetPage);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _syncImageUrls();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BottomModalImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      final count = _knownImageCount(widget.entry);
      final controller = _pageController;
      if (controller != null && controller.hasClients && count > 1) {
        controller.jumpToPage(_initialVirtualPage(count));
      }
    }
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

  void _configurePageController(double viewportWidth, int itemCount) {
    final targetPageExtent = _carouselPageExtent(viewportWidth);
    final viewportFraction = (targetPageExtent / viewportWidth).clamp(0.0, 1.0);

    final PageController? currentController = _pageController;
    if (currentController != null &&
        _viewportFraction != null &&
        (_viewportFraction! - viewportFraction).abs() < 0.001) {
      return;
    }

    final int initialPage = currentController?.hasClients == true
        ? (currentController!.page ?? _initialVirtualPage(itemCount).toDouble())
              .round()
        : _initialVirtualPage(itemCount);
    _viewportFraction = viewportFraction;
    _pageController = PageController(
      viewportFraction: viewportFraction,
      initialPage: initialPage,
    );
    if (currentController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        currentController.dispose();
      });
    }
  }

  double _carouselCurrentPage() {
    final PageController? controller = _pageController;
    if (controller == null ||
        !controller.hasClients ||
        controller.positions.length != 1) {
      return _initialVirtualPage(1).toDouble();
    }
    return controller.page ?? _initialVirtualPage(1).toDouble();
  }

  int _activeImageIndexFromController(int itemCount) {
    if (itemCount <= 1) return 0;
    return _imageIndexForPage(_carouselCurrentPage().round(), itemCount);
  }

  Widget _clipCarouselTile({required Widget child}) {
    final outerRadius = widget.imageOuterBorderRadius;
    if (outerRadius != null) {
      return ClipSmoothRect(
        radius: AppSquircle.borderRadiusNested(
          outerRadius: outerRadius,
          inset: _verticalInset,
        ),
        child: child,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: child,
    );
  }

  Widget _buildCarouselTileContent({
    required double width,
    required Widget child,
  }) {
    return _clipCarouselTile(
      child: SizedBox(
        width: width,
        height: _carouselContentHeight(),
        child: child,
      ),
    );
  }

  Widget _buildCarouselPage({
    required double imageWidth,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalInset,
        _verticalInset,
        0,
        _verticalInset,
      ),
      child: Row(
        children: [
          _buildCarouselTileContent(
            width: imageWidth,
            child: child,
          ),
          SizedBox(width: _imageGap),
        ],
      ),
    );
  }

  Widget _buildSingleCarouselImage({
    required Widget child,
    required double imageWidth,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalInset,
        _verticalInset,
        _horizontalInset,
        _verticalInset,
      ),
      child: _buildCarouselTileContent(width: imageWidth, child: child),
    );
  }

  Widget _buildPageCounter(int current, int total) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '$current von $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSnappingCarousel({
    required int itemCount,
    required Widget Function(int index) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final imageWidth = _carouselImageWidth(viewportWidth);
        _configurePageController(viewportWidth, itemCount);
        final controller = _pageController!;

        if (itemCount <= 1) {
          return _buildSingleCarouselImage(
            imageWidth: imageWidth,
            child: itemBuilder(0),
          );
        }

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            PageView.builder(
              controller: controller,
              clipBehavior: Clip.none,
              padEnds: false,
              onPageChanged: (index) =>
                  _onCarouselPageChanged(index, itemCount),
              itemBuilder: (context, index) {
                final imageIndex = _imageIndexForPage(index, itemCount);
                return _buildCarouselPage(
                  imageWidth: imageWidth,
                  child: itemBuilder(imageIndex),
                );
              },
            ),
            Positioned(
              right: _horizontalInset,
              bottom: _verticalInset,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  final activeIndex =
                      _activeImageIndexFromController(itemCount);
                  return _buildPageCounter(activeIndex + 1, itemCount);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarouselContent({
    required bool isLoading,
    required bool hasError,
    required List<String> imageUrls,
    required Color imagePanelBg,
  }) {
    if (isLoading) {
      final itemCount = _carouselLoadingPlaceholderCount();
      return _buildSnappingCarousel(
        itemCount: itemCount,
        itemBuilder: (index) => const SkeletonLoader(),
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
    return _buildSnappingCarousel(
      itemCount: imageUrls.length,
      itemBuilder: (index) => CachedNetworkImage(
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
        placeholder: (context, _) => const SkeletonLoader(),
        errorWidget: (context, _, _) => ColoredBox(
          color: imagePanelBg,
          child: const Icon(Icons.broken_image, size: 50),
        ),
      ),
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
        child: const SkeletonLoader(),
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
        placeholder: (context, _) => const SkeletonLoader(),
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
