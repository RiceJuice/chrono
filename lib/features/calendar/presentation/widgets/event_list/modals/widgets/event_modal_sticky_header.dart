import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/widgets/event_bottom_modal_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Bild-Karussell: kollabiert beim Scrollen, behält einen Streifen sichtbar.
class EventModalCollapsingImageHeaderSliver extends StatelessWidget {
  const EventModalCollapsingImageHeaderSliver({
    super.key,
    required this.child,
    this.maxHeight = EventBottomModalTypography.imageHeaderMaxHeight,
    this.minHeight = EventBottomModalTypography.imageHeaderPinnedPeekHeight,
  });

  final Widget child;
  final double maxHeight;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _EventModalCollapsingImageHeaderDelegate(
        maxHeight: maxHeight,
        minHeight: minHeight,
        child: child,
      ),
    );
  }
}

class _EventModalCollapsingImageHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  _EventModalCollapsingImageHeaderDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.child,
  });

  final double maxHeight;
  final double minHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final visibleHeight =
        (maxHeight - shrinkOffset).clamp(minHeight, maxHeight).toDouble();

    return SizedBox(
      height: visibleHeight,
      width: double.infinity,
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: SizedBox(
            height: maxHeight,
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EventModalCollapsingImageHeaderDelegate old) {
    return old.maxHeight != maxHeight ||
        old.minHeight != minHeight ||
        old.child != child;
  }
}

/// Gepinnter Sheet-Header mit dynamischer Höhe (misst sich nach Layout).
class EventModalStickyHeaderSliver extends StatefulWidget {
  const EventModalStickyHeaderSliver({
    super.key,
    required this.backgroundColor,
    required this.child,
    this.allowChildOverflow = false,
  });

  final Color backgroundColor;
  final Widget child;

  /// Erlaubt z. B. einen Scroll-Hinweis unterhalb des Headers ohne Höhenänderung.
  final bool allowChildOverflow;

  @override
  State<EventModalStickyHeaderSliver> createState() =>
      _EventModalStickyHeaderSliverState();
}

class _EventModalStickyHeaderSliverState
    extends State<EventModalStickyHeaderSliver> {
  final GlobalKey _measureKey = GlobalKey();
  double _extent = 64;

  @override
  void initState() {
    super.initState();
    _scheduleRemeasure();
  }

  @override
  void didUpdateWidget(covariant EventModalStickyHeaderSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child ||
        oldWidget.backgroundColor != widget.backgroundColor) {
      _scheduleRemeasure();
    }
  }

  void _scheduleRemeasure() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  void _remeasure() {
    if (!mounted) return;
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final nextExtent = box.size.height;
    if ((nextExtent - _extent).abs() < 0.5) return;
    setState(() => _extent = nextExtent);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _EventModalStickyHeaderDelegate(
        extent: _extent,
        backgroundColor: widget.backgroundColor,
        allowChildOverflow: widget.allowChildOverflow,
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            _scheduleRemeasure();
            return false;
          },
          child: SizeChangedLayoutNotifier(
            child: KeyedSubtree(
              key: _measureKey,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventModalStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _EventModalStickyHeaderDelegate({
    required this.extent,
    required this.backgroundColor,
    required this.child,
    this.allowChildOverflow = false,
  });

  final double extent;
  final Color backgroundColor;
  final Widget child;
  final bool allowChildOverflow;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: extent,
      width: double.infinity,
      child: ColoredBox(
        color: backgroundColor,
        child: Stack(
          clipBehavior:
              allowChildOverflow ? Clip.none : Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EventModalStickyHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.child != child ||
        oldDelegate.allowChildOverflow != allowChildOverflow;
  }
}
