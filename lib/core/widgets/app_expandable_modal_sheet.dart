import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
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
  });

  /// `(scrollController, maxSheetHeight, isFullyExpanded)` — Inhalt als
  /// [CustomScrollView]-Slivers; [isFullyExpanded] für verschachtelte Listen.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    double maxSheetHeight,
    bool isFullyExpanded,
  ) builder;

  final Color? color;
  final double initialChildSize;
  final double minChildSize;

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
        snapAnimationDuration: const Duration(milliseconds: 280),
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
                widget.builder(
                  context,
                  scrollController,
                  maxSheetHeight,
                  _isFullyExpanded,
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
