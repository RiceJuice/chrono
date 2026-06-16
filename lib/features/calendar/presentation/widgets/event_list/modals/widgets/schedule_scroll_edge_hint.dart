import 'dart:async';

import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum ScheduleScrollHintDirection { up, down }

/// Dezenter Scroll-Hinweis am Rand — reines Overlay, kein Scroll-Layout.
class ScheduleScrollEdgeHint extends StatelessWidget {
  const ScheduleScrollEdgeHint({
    super.key,
    required this.direction,
    required this.visible,
    required this.pulse,
    required this.surfaceColor,
    required this.iconColor,
  });

  final ScheduleScrollHintDirection direction;
  final bool visible;
  final Animation<double> pulse;
  final Color surfaceColor;
  final Color iconColor;

  static const double height = 18;

  bool get _pointsUp => direction == ScheduleScrollHintDirection.up;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final bounce = Curves.easeOutCubic.transform(pulse.value);
              final delta = bounce * 3;
              return Transform.translate(
                offset: Offset(0, _pointsUp ? delta : -delta),
                child: child,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _pointsUp ? Alignment.topCenter : Alignment.bottomCenter,
                  end: _pointsUp ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: [
                    surfaceColor,
                    surfaceColor.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Align(
                alignment: _pointsUp
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: Icon(
                  _pointsUp
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: iconColor.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bounce-Hinweis am unteren Sheet-Rand, wenn das Ende des Ablaufs erreicht ist.
class ScheduleScrollEndHintOverlay extends StatefulWidget {
  const ScheduleScrollEndHintOverlay({
    super.key,
    required this.controller,
    required this.surfaceColor,
    required this.enabled,
    required this.iconColor,
  });

  final ScrollController controller;
  final Color surfaceColor;
  final bool enabled;
  final Color iconColor;

  @override
  State<ScheduleScrollEndHintOverlay> createState() =>
      _ScheduleScrollEndHintOverlayState();
}

class _ScheduleScrollEndHintOverlayState extends State<ScheduleScrollEndHintOverlay>
    with SingleTickerProviderStateMixin {
  static const double _endThreshold = 2;
  static const double _minScrollableExtent = 24;
  static const Duration _hapticDebounce = Duration(milliseconds: 280);

  late final AnimationController _pulseController;
  ScrollController? _attachedController;
  bool _visible = false;
  DateTime? _lastHapticAt;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _attachScrollListener();
  }

  @override
  void didUpdateWidget(covariant ScheduleScrollEndHintOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _visible) {
      _visible = false;
    }
    _attachScrollListener();
  }

  @override
  void dispose() {
    _detachScrollListener();
    _pulseController.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    if (!widget.enabled) {
      _detachScrollListener();
      return;
    }
    if (widget.controller == _attachedController) return;
    _detachScrollListener();
    _attachedController = widget.controller;
    widget.controller.addListener(_onScroll);
  }

  void _detachScrollListener() {
    _attachedController?.removeListener(_onScroll);
    _attachedController = null;
  }

  void _onScroll() {
    if (!mounted || !widget.enabled) return;

    final controller = widget.controller;
    if (!controller.hasClients) return;

    final position = controller.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent < _minScrollableExtent) return;

    final offset = position.pixels;
    final atEnd = offset >= position.maxScrollExtent - _endThreshold;
    final pushingPastEnd =
        atEnd && position.userScrollDirection == ScrollDirection.forward;

    if (pushingPastEnd) {
      final now = DateTime.now();
      final lastHaptic = _lastHapticAt;
      if (lastHaptic == null || now.difference(lastHaptic) >= _hapticDebounce) {
        _lastHapticAt = now;
        AppHaptics.light();
      }
      if (!_visible) {
        setState(() => _visible = true);
      }
      if (mounted) {
        unawaited(_pulseController.forward(from: 0));
      }
    } else if (!atEnd && _visible) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return ScheduleScrollEdgeHint(
      direction: ScheduleScrollHintDirection.down,
      visible: _visible,
      pulse: _pulseController,
      surfaceColor: widget.surfaceColor,
      iconColor: widget.iconColor,
    );
  }
}
