import 'package:chronoapp/core/widgets/app_modal_scroll_surface.dart';
import 'package:flutter/material.dart';

/// Fester Viewport für die Ablauf-Liste — scrollt isoliert vom äußeren Modal.
///
/// Touch-Events in diesem Bereich gehen an [child] (die innere Liste).
/// Runterziehen am oberen Rand beider Scrolls wird an den äußeren Sheet-Scroll
/// durchgereicht, damit das Modal verkleinert werden kann.
class EventModalScheduleScrollViewport extends StatefulWidget {
  const EventModalScheduleScrollViewport({
    super.key,
    required this.height,
    required this.scrollController,
    this.outerScrollController,
    required this.isSheetFullyExpanded,
    required this.child,
  });

  final double height;
  final ScrollController scrollController;
  final ScrollController? outerScrollController;
  final bool isSheetFullyExpanded;
  final Widget child;

  @override
  State<EventModalScheduleScrollViewport> createState() =>
      _EventModalScheduleScrollViewportState();
}

class _EventModalScheduleScrollViewportState
    extends State<EventModalScheduleScrollViewport> {
  static const double _topTolerance = 0.5;
  static const double _directionThreshold = 6;

  double? _pointerStartY;
  bool _forwardPullDownToOuter = false;

  bool get _atEffectiveTop {
    final outer = widget.outerScrollController;
    if (!widget.isSheetFullyExpanded || outer == null) return false;
    if (!widget.scrollController.hasClients || !outer.hasClients) {
      return false;
    }
    return widget.scrollController.offset <= _topTolerance &&
        outer.offset <= _topTolerance;
  }

  void _resetPointerState() {
    _pointerStartY = null;
    if (_forwardPullDownToOuter) {
      setState(() => _forwardPullDownToOuter = false);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerStartY = event.position.dy;
    if (_forwardPullDownToOuter) {
      setState(() => _forwardPullDownToOuter = false);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_atEffectiveTop || _pointerStartY == null) return;

    final delta = event.position.dy - _pointerStartY!;
    if (delta > _directionThreshold) {
      if (!_forwardPullDownToOuter) {
        setState(() => _forwardPullDownToOuter = true);
      }
      return;
    }
    if (delta < -_directionThreshold && _forwardPullDownToOuter) {
      setState(() => _forwardPullDownToOuter = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ignoreInner =
        !widget.isSheetFullyExpanded || _forwardPullDownToOuter;

    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => _resetPointerState(),
        onPointerCancel: (_) => _resetPointerState(),
        child: IgnorePointer(
          ignoring: ignoreInner,
          child: AppModalScrollSurface(
            controller: widget.scrollController,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
