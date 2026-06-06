import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Scrollbar für Modal-Sheets — iOS-ähnlich, Thumb bei Scroll sichtbar.
class AppModalScrollSurface extends StatefulWidget {
  const AppModalScrollSurface({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<AppModalScrollSurface> createState() => _AppModalScrollSurfaceState();
}

class _AppModalScrollSurfaceState extends State<AppModalScrollSurface> {
  Timer? _hideScrollbarTimer;
  bool _thumbVisible = false;

  static const Duration _hideDelay = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollActivity);
  }

  @override
  void didUpdateWidget(covariant AppModalScrollSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScrollActivity);
      widget.controller.addListener(_onScrollActivity);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollActivity);
    _hideScrollbarTimer?.cancel();
    super.dispose();
  }

  void _onScrollActivity() {
    if (!widget.controller.hasClients) return;
    _revealThumb();
  }

  void _revealThumb() {
    _hideScrollbarTimer?.cancel();
    if (!_thumbVisible && mounted) {
      setState(() => _thumbVisible = true);
    }
    _hideScrollbarTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _thumbVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoScrollbar(
        controller: widget.controller,
        thumbVisibility: _thumbVisible,
        thickness: 2.5,
        radius: const Radius.circular(100),
        child: widget.child,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbVisibility: WidgetStatePropertyAll<bool>(_thumbVisible),
        thickness: WidgetStatePropertyAll<double>(2.5),
        radius: const Radius.circular(100),
        crossAxisMargin: 2,
        mainAxisMargin: 4,
        thumbColor: WidgetStatePropertyAll<Color>(
          scheme.onSurface.withValues(alpha: 0.28),
        ),
      ),
      child: Scrollbar(
        controller: widget.controller,
        thumbVisibility: _thumbVisible,
        child: widget.child,
      ),
    );
  }
}
