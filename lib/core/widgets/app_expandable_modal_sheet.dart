import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_top_glass_blend.dart';
import 'package:flutter/material.dart';

/// Anteil der Bildschirmhöhe beim ersten Öffnen (Apple-Maps-Stil).
const double kAppExpandableModalInitialSize = 0.6;

/// Event-Detail: etwas höher, damit Beschreibung und Ablauf sichtbar sind.
const double kAppExpandableModalEventInitialSize = 0.65;

/// Minimale Sheet-Höhe zum Herunterziehen / Schließen.
const double kAppExpandableModalMinSize = 0.35;

/// Detail-Bottom-Sheet: expandiert zuerst, scrollt danach den Inhalt.
class AppExpandableModalSheet extends StatefulWidget {
  const AppExpandableModalSheet({
    super.key,
    required this.builder,
    this.color,
    this.initialChildSize = kAppExpandableModalInitialSize,
    this.minChildSize = kAppExpandableModalMinSize,
    this.showTopGlassBlend = false,
  });

  /// `(scrollController, maxSheetHeight)` — Inhalt als [CustomScrollView]-Slivers.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double maxSheetHeight,
  ) builder;

  final Color? color;
  final double initialChildSize;
  final double minChildSize;

  /// Frosted-Glass-Verlauf oben, unter dem Drag-Handle (z. B. Event-Detail).
  final bool showTopGlassBlend;

  static double maxChildSizeFraction(BuildContext context) {
    final view = appSheetViewMediaQuery(context);
    return appSheetHeightBelowSystemUi(context) / view.size.height;
  }

  @override
  State<AppExpandableModalSheet> createState() =>
      _AppExpandableModalSheetState();
}

class _AppExpandableModalSheetState extends State<AppExpandableModalSheet> {
  bool _isFullyExpanded = false;

  bool _onSheetNotification(DraggableScrollableNotification notification) {
    if (notification.depth != 0) return false;

    final isFullyExpanded =
        notification.extent >= notification.maxExtent - 0.001;
    if (isFullyExpanded == _isFullyExpanded) return false;

    setState(() => _isFullyExpanded = isFullyExpanded);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final view = appSheetViewMediaQuery(context);
    final maxChildSize = appSheetHeightBelowSystemUi(context) / view.size.height;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onSheetNotification,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: maxChildSize,
        snap: true,
        snapSizes: [widget.initialChildSize, maxChildSize],
        builder: (context, scrollController) {
          final maxSheetHeight = view.size.height * maxChildSize;
          final scheme = Theme.of(context).colorScheme;
          final bg = widget.color ?? scheme.surfaceContainer;

          return AppModalSheetChrome(
            color: bg,
            clipTopCorners: true,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.builder(context, scrollController, maxSheetHeight),
                if (widget.showTopGlassBlend)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    // Eigenes, isoliertes Widget: zeichnet beim Scrollen nur
                    // den Glass-Verlauf neu — nicht den ganzen CustomScrollView.
                    child: _TopGlassBlend(
                      controller: scrollController,
                      isFullyExpanded: _isFullyExpanded,
                    ),
                  ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: BottomModalHandle(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Reiner Glass-Verlauf, der sich beim Scrollen unabhängig vom Sheet-Inhalt
/// aktualisiert, damit der äußere Scroll nicht jeden Frame neu gebaut wird.
class _TopGlassBlend extends StatefulWidget {
  const _TopGlassBlend({
    required this.controller,
    required this.isFullyExpanded,
  });

  final ScrollController controller;
  final bool isFullyExpanded;

  @override
  State<_TopGlassBlend> createState() => _TopGlassBlendState();
}

class _TopGlassBlendState extends State<_TopGlassBlend> {
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _TopGlassBlend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final offset = widget.controller.offset;
    if (offset == _offset) return;
    setState(() => _offset = offset);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = bottomModalTopGlassBlendOpacity(
      isFullyExpanded: widget.isFullyExpanded,
      contentScrollOffset: widget.isFullyExpanded ? _offset : 0,
    );
    return BottomModalTopGlassBlend(opacity: opacity);
  }
}
