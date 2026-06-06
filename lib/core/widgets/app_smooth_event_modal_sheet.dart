import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/bottom_modal_header.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Modal-Einstieg für Event-/Break-Detail-Sheets via [smooth_sheets].
abstract final class AppSmoothModalSheet {
  AppSmoothModalSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    Color? barrierColor,
  }) {
    AppModalSheetTracker.retainMainNavigationHidden();
    final resolvedBarrier = barrierColor ?? Colors.black54;
    final dismissSensitivity = SwipeDismissSensitivity(
      dismissalOffset: SheetOffset.proportionalToViewport(
        kAppEventModalMinSize,
      ),
    );

    final Future<T?> route;
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      route = showCupertinoModalSheet<T>(
        context: context,
        useRootNavigator: true,
        swipeDismissible: true,
        barrierColor: resolvedBarrier,
        transitionDuration: kAppModalSheetMotion.duration,
        transitionCurve: kAppModalSheetMotion.curve,
        swipeDismissSensitivity: dismissSensitivity,
        builder: (ctx) => AppModalSheetMediaScope(child: builder(ctx)),
      );
    } else {
      route = showModalSheet<T>(
        context: context,
        useRootNavigator: true,
        swipeDismissible: true,
        barrierColor: resolvedBarrier,
        transitionDuration: kAppModalSheetMotion.duration,
        transitionCurve: kAppModalSheetMotion.curve,
        swipeDismissSensitivity: dismissSensitivity,
        viewportPadding: EdgeInsets.only(top: appSheetTopOffset(context)),
        builder: (ctx) => AppModalSheetMediaScope(child: builder(ctx)),
      );
    }

    return route.whenComplete(AppModalSheetTracker.releaseMainNavigationHidden);
  }
}

/// Event-Detail-Bottom-Sheet: ein koordinierter Scroll via [smooth_sheets].
class AppSmoothEventModalSheet extends StatefulWidget {
  const AppSmoothEventModalSheet({
    super.key,
    required this.builder,
    this.color,
    this.initialSize = kAppEventModalInitialSize,
  });

  /// `(scrollController, isFullyExpanded)` — Inhalt als scrollbare Slivers.
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    bool isFullyExpanded,
  ) builder;

  final Color? color;
  final double initialSize;

  @override
  State<AppSmoothEventModalSheet> createState() =>
      _AppSmoothEventModalSheetState();
}

class _AppSmoothEventModalSheetState extends State<AppSmoothEventModalSheet> {
  static const SheetOffset _fullSnap = SheetOffset(1);

  late final SheetController _sheetController;
  late final SheetScrollController _contentScrollController;
  bool _isFullyExpanded = false;

  SheetOffset get _initialSnap =>
      SheetOffset.proportionalToViewport(widget.initialSize);

  @override
  void initState() {
    super.initState();
    _sheetController = SheetController();
    _contentScrollController = SheetScrollController();
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  bool _onSheetNotification(SheetNotification notification) {
    final metrics = notification.metrics;
    final isFullyExpanded = metrics.offset >= metrics.maxOffset - 0.001;
    if (isFullyExpanded == _isFullyExpanded) return false;
    setState(() => _isFullyExpanded = isFullyExpanded);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.color ?? scheme.surfaceContainer;

    return NotificationListener<SheetNotification>(
      onNotification: _onSheetNotification,
      child: Sheet(
        controller: _sheetController,
        initialOffset: _initialSnap,
        snapGrid: SheetSnapGrid(snaps: [_initialSnap, _fullSnap]),
        scrollConfiguration: const SheetScrollConfiguration(
          scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
        ),
        decoration: MaterialSheetDecoration(
          size: SheetSize.fit,
          color: Colors.transparent,
          clipBehavior: Clip.none,
        ),
        child: AppModalSheetChrome(
          color: bg,
          clipTopCorners: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SheetScrollable(
                controller: _contentScrollController,
                child: widget.builder(
                  context,
                  _contentScrollController,
                  _isFullyExpanded,
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
        ),
      ),
    );
  }
}
