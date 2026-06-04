import 'dart:io';

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/calendar_event_pending_attachment.dart';

const _domspatzenAssetPath = 'assets/domspatzen.svg';

/// Vorschau: bündig oben im Modal, volle Breite, Hochformat — Metadaten unten.
class EventFormAttachmentFocusView extends StatefulWidget {
  const EventFormAttachmentFocusView({
    super.key,
    required this.attachments,
    this.onRemove,
    this.uploading = false,
  });

  final List<CalendarEventPendingAttachment> attachments;
  final ValueChanged<String>? onRemove;
  final bool uploading;

  @override
  State<EventFormAttachmentFocusView> createState() =>
      _EventFormAttachmentFocusViewState();
}

class _EventFormAttachmentFocusViewState
    extends State<EventFormAttachmentFocusView> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final items = widget.attachments;
    if (items.isEmpty) return const SizedBox.shrink();

    final current = items[_pageIndex.clamp(0, items.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _FullWidthImageCarousel(
            items: items,
            pageController: _pageController,
            uploading: widget.uploading,
            pageIndex: _pageIndex,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            scheme: scheme,
          ),
        ),
        _PreviewMetaSection(
          attachment: current,
          showWatermark: current.isImage,
          uploading: widget.uploading,
          onRemove: widget.onRemove,
          theme: theme,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _FullWidthImageCarousel extends StatelessWidget {
  const _FullWidthImageCarousel({
    required this.items,
    required this.pageController,
    required this.uploading,
    required this.pageIndex,
    required this.onPageChanged,
    required this.scheme,
  });

  final List<CalendarEventPendingAttachment> items;
  final PageController pageController;
  final bool uploading;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final index = pageIndex.clamp(0, items.length - 1);

    final pager = items.length == 1
        ? _AttachmentPreviewContent(attachment: items.first)
        : PageView.builder(
            controller: pageController,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) =>
                _AttachmentPreviewContent(attachment: items[i]),
          );

    return ClipSmoothRect(
      radius: AppSquircle.bottomSheet(AppRadius.sheet),
      child: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.topCenter,
          children: [
            pager,
            if (uploading)
              ColoredBox(
                color: scheme.scrim.withValues(alpha: 0.18),
                child: Center(
                  child: SizedBox.square(
                    dimension: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (items.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.m,
                child: _PageIndicator(
                  count: items.length,
                  index: index,
                  color: scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetaSection extends StatelessWidget {
  const _PreviewMetaSection({
    required this.attachment,
    required this.showWatermark,
    required this.uploading,
    required this.onRemove,
    required this.theme,
    required this.scheme,
  });

  final CalendarEventPendingAttachment attachment;
  final bool showWatermark;
  final bool uploading;
  final ValueChanged<String>? onRemove;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (uploading)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Text(
                'Wird hochgeladen …',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (showWatermark) ...[
            _DomspatzenWatermark(color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.s),
          ],
          Text(
            attachment.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: -0.1,
            ),
          ),
          if (!uploading && onRemove != null) ...[
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: () => onRemove!(attachment.id),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error.withValues(alpha: 0.88),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.s,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Entfernen'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentPreviewContent extends StatelessWidget {
  const _AttachmentPreviewContent({required this.attachment});

  final CalendarEventPendingAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return Image.file(
        File(attachment.localPath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) =>
            _DocumentPreview(attachment: attachment),
      );
    }

    return _DocumentPreview(attachment: attachment);
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.attachment});

  final CalendarEventPendingAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isPdf) {
      return _PdfPreview(attachment: attachment);
    }
    return _GenericFilePreview(attachment: attachment);
  }
}

class _GenericFilePreview extends StatelessWidget {
  const _GenericFilePreview({required this.attachment});

  final CalendarEventPendingAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              attachment.displayName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  const _PdfPreview({required this.attachment});

  final CalendarEventPendingAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'PDF',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              attachment.displayName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomspatzenWatermark extends StatelessWidget {
  const _DomspatzenWatermark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.18,
        child: SvgPicture.asset(
          _domspatzenAssetPath,
          height: 28,
          width: 28,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.index,
    required this.color,
  });

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: active
                ? color.withValues(alpha: 0.88)
                : color.withValues(alpha: 0.28),
          ),
        );
      }),
    );
  }
}
