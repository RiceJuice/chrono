import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/data/calendar_image_url_resolver.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BottomModalImages extends StatefulWidget {
  final CalendarEntry entry;
  final double height;
  const BottomModalImages({super.key, required this.entry, this.height = 120});

  @override
  State<BottomModalImages> createState() => _BottomModalImagesState();
}

class _BottomModalImagesState extends State<BottomModalImages> {
  static final CalendarImageUrlResolver _imageUrlResolver =
      CalendarImageUrlResolver(supabase: Supabase.instance.client);
  late Future<List<String>> _imageUrlsFuture;

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

  @override
  Widget build(BuildContext context) {
    final imagePanelBg = Theme.of(context).colorScheme.surface;
    return FutureBuilder<List<String>>(
      future: _imageUrlsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final imageUrls = snapshot.data ?? const <String>[];
        final hasError = snapshot.hasError;

        Widget content;
        if (isLoading) {
          content = ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 2,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: imagePanelBg),
                  ),
                ),
              );
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
          content = ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    cacheKey: _cacheKeyForImage(index, imageUrls[index]),
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, _) => Container(color: imagePanelBg),
                    errorWidget: (context, _, _) => Container(
                      color: imagePanelBg,
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return Stack(
          children: [
            SizedBox(
              height: 200,
              child: ColoredBox(color: imagePanelBg, child: content),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ],
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
