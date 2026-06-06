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
class AppExpandableModalSheet extends StatelessWidget {
  const AppExpandableModalSheet({
    super.key,
    required this.builder,
    this.color,
    this.initialChildSize = kAppExpandableModalInitialSize,
    this.minChildSize = kAppExpandableModalMinSize,
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

  static double maxChildSizeFraction(BuildContext context) {
    final view = appSheetViewMediaQuery(context);
    return appSheetHeightBelowSystemUi(context) / view.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final view = appSheetViewMediaQuery(context);
    final maxChildSize = appSheetHeightBelowSystemUi(context) / view.size.height;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: [initialChildSize, maxChildSize],
      builder: (context, scrollController) {
        final maxSheetHeight = view.size.height * maxChildSize;
        final scheme = Theme.of(context).colorScheme;
        final bg = color ?? scheme.surfaceContainer;

        return AppModalSheetChrome(
          color: bg,
          clipTopCorners: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              builder(context, scrollController, maxSheetHeight),
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
    );
  }
}
