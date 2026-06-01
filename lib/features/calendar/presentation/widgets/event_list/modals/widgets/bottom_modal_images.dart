import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_url_resolver.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart'
    show BottomModalHandle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _tileGap = 5.0;
const _imageAspectRatio = 1.5;
/// Sichtbarer Streifen des nächsten Bildes — verhindert zwei halbe Kacheln mit Lücke am Rand.
const _nextImagePeek = 32.0;

class BottomModalImages extends StatefulWidget {
  final CalendarEntry entry;
  final double height;
  final bool clipTopCorners;

  const BottomModalImages({
    super.key,
    required this.entry,
    this.height = 120,
    this.clipTopCorners = false,
  });

  @override
  State<BottomModalImages> createState() => _BottomModalImagesState();
}

class _BottomModalImagesState extends State<BottomModalImages> {
  static final CalendarImageUrlResolver _imageUrlResolver =
      CalendarImageUrlResolver(supabase: Supabase.instance.client);
  late Future<List<String>> _imageUrlsFuture;

  double _tileWidth(double panelWidth, int itemCount) {
    if (itemCount <= 1) return panelWidth;
    return panelWidth - _nextImagePeek;
  }

  double _stripHeight(double panelWidth, int itemCount) {
    final tileWidth = _tileWidth(panelWidth, itemCount);
    return tileWidth / _imageAspectRatio;
  }

  @override
  void initState() {
    super.initState();
    _imageUrlsFuture = _resolveImageUrls(widget.entry);
  }

  @override
  void didUpdateWidget(covariant BottomModalImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        !listEquals(oldWidget.entry.imageUrls, widget.entry.imageUrls) ||
        !listEquals(oldWidget.entry.imagePaths, widget.entry.imagePaths)) {
      _imageUrlsFuture = _resolveImageUrls(widget.entry);
    }
  }

  Future<List<String>> _resolveImageUrls(CalendarEntry entry) async {
    final existingUrls = entry.imageUrls;
    if (existingUrls != null && existingUrls.isNotEmpty) return existingUrls;

    final imagePaths = entry.imagePaths;
    if (imagePaths == null || imagePaths.isEmpty) return const <String>[];
    return await _imageUrlResolver.resolveSignedUrls(imagePaths) ??
        const <String>[];
  }

  String _cacheKeyForImage(int index, String imageUrl) {
    final paths = widget.entry.imagePaths;
    final sourceKey = (paths != null && paths.length > index)
        ? paths[index]
        : imageUrl;
    return 'calendar-modal-${widget.entry.id}-$index-$sourceKey';
  }

  Widget _imageTile({
    required double width,
    required double height,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildImageStrip({
    required double panelWidth,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    final stripHeight = _stripHeight(panelWidth, itemCount);
    final tileWidth = _tileWidth(panelWidth, itemCount);

    if (itemCount <= 1) {
      return _imageTile(
        width: tileWidth,
        height: stripHeight,
        child: itemBuilder(context, 0),
      );
    }

    return SizedBox(
      height: stripHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == itemCount - 1 ? 0 : _tileGap,
            ),
            child: _imageTile(
              width: tileWidth,
              height: stripHeight,
              child: itemBuilder(context, index),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePanelBg = Theme.of(context).colorScheme.surface;
    return FutureBuilder<List<String>>(
      future: _imageUrlsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final imageUrls = snapshot.data ?? const <String>[];
        final hasError = snapshot.hasError;

        return LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth;
            final itemCount = isLoading
                ? 2
                : hasError || imageUrls.isEmpty
                ? 1
                : imageUrls.length;
            final stripHeight = _stripHeight(panelWidth, itemCount);

            Widget content;
            if (isLoading) {
              content = _buildImageStrip(
                panelWidth: panelWidth,
                itemCount: 2,
                itemBuilder: (context, index) {
                  return ColoredBox(color: imagePanelBg);
                },
              );
            } else if (hasError) {
              content = _NoImageState(
                icon: Icons.error_outline,
                text: 'Bilder konnten nicht geladen werden.',
              );
            } else if (imageUrls.isEmpty) {
              content = _NoImageState(
                icon: Icons.image_not_supported_outlined,
                text: 'Keine Bilder vorhanden.',
              );
            } else {
              content = _buildImageStrip(
                panelWidth: panelWidth,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    cacheKey: _cacheKeyForImage(index, imageUrls[index]),
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, _) =>
                        ColoredBox(color: imagePanelBg),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: imagePanelBg,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  );
                },
              );
            }

            final contentSized = SizedBox(
              height: stripHeight,
              width: panelWidth,
              child: ColoredBox(color: imagePanelBg, child: content),
            );

            final panel = Stack(
              children: [
                if (widget.clipTopCorners)
                  contentSized
                else
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.m + 1),
                      topRight: Radius.circular(AppRadius.m + 1),
                    ),
                    child: contentSized,
                  ),
                const BottomModalHandle(),
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
          },
        );
      },
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
