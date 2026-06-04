import 'package:flutter/material.dart';

import 'dialogs/event_image_attach_sheet.dart';
import 'event_attach_source_panel.dart';

/// iOS-ähnliches Einblenden der Dateiquellen (Höhe, Fade, leichter Slide, gestaffelt).
class EventAttachSourceReveal extends StatefulWidget {
  const EventAttachSourceReveal({
    super.key,
    required this.visible,
    required this.onSelected,
  });

  final bool visible;
  final ValueChanged<EventImageAttachSource> onSelected;

  @override
  State<EventAttachSourceReveal> createState() => _EventAttachSourceRevealState();
}

class _EventAttachSourceRevealState extends State<EventAttachSourceReveal>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 420);
  static const Curve _expandCurve = Cubic(0.32, 0.72, 0, 1);

  late final AnimationController _controller;
  late final Animation<double> _expand;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _expand = CurvedAnimation(parent: _controller, curve: _expandCurve);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.75, curve: Curves.easeOut),
    );
    if (widget.visible) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(EventAttachSourceReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: EventAttachSourcePanel(
        onSelected: widget.onSelected,
        revealAnimation: _expand,
      ),
      builder: (context, child) {
        if (_controller.value == 0) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _expand.value.clamp(0, 1),
            child: Opacity(
              opacity: _fade.value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - _expand.value)),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
