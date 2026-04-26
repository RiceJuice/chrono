import 'package:flutter/material.dart';

/// Scrollbar mit dauerhaft sichtbarem Griff + [SingleChildScrollView] für den Login-Flow.
class LoginScrollSurface extends StatefulWidget {
  const LoginScrollSurface({
    super.key,
    required this.child,
    this.contentMinHeight,
    this.scrollPadding = EdgeInsets.zero,
  });

  final Widget child;

  /// Optional: Mindesthöhe (z. B. Viewport), damit [MainAxisAlignment.spaceBetween] wirkt.
  final double? contentMinHeight;

  /// Zusätzliches Padding innerhalb der Scroll-View (ohne Tastatur-Inset).
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
    // Kein zusätzliches viewInsets.bottom: [Scaffold] mit resizeToAvoidBottomInset
    // (Standard true) verkleinert den Body bereits — doppeltes Padding erzeugt Sprünge
    // beim Scrollen mit offener Tastatur.
    final EdgeInsets padding = widget.scrollPadding;

    Widget body = widget.child;
    final double? minH = widget.contentMinHeight;
    if (minH != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minH),
        child: body,
      );
    }

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
          // onDrag schließt die Tastatur bei jeder Scroll-Geste und wirkt wie „Rausspringen“.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
