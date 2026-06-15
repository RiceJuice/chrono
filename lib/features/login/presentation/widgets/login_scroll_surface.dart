import 'package:flutter/material.dart';

/// Scrollbar mit sichtbarem Griff für den Login-Flow.
class LoginScrollSurface extends StatefulWidget {
  const LoginScrollSurface({
    super.key,
    required this.child,
    this.scrollPadding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets scrollPadding;

  static ScrollbarThemeData _scrollbarTheme(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll<bool>(true),
      thickness: const WidgetStatePropertyAll<double>(3.5),
      radius: const Radius.circular(4),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
      thumbColor: WidgetStatePropertyAll<Color>(
        scheme.onSurface.withValues(alpha: 0.38),
      ),
    );
  }

  @override
  State<LoginScrollSurface> createState() => _LoginScrollSurfaceState();
}

class _LoginScrollSurfaceState extends State<LoginScrollSurface> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(scrollbarTheme: LoginScrollSurface._scrollbarTheme(context)),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: widget.scrollPadding,
          child: widget.child,
        ),
      ),
    );
  }
}
