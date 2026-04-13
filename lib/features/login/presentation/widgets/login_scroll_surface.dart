import 'package:flutter/material.dart';

/// Scrollbar mit dauerhaft sichtbarem Griff + [SingleChildScrollView] für den Login-Flow.
class LoginScrollSurface extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Kein zusätzliches viewInsets.bottom: [Scaffold] mit resizeToAvoidBottomInset
    // (Standard true) verkleinert den Body bereits — doppeltes Padding erzeugt Sprünge
    // beim Scrollen mit offener Tastatur.
    final EdgeInsets padding = scrollPadding;

    Widget body = child;
    final double? minH = contentMinHeight;
    if (minH != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minH),
        child: body,
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: _scrollbarTheme(context),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          // onDrag schließt die Tastatur bei jeder Scroll-Geste und wirkt wie „Rausspringen“.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: padding,
          child: body,
        ),
      ),
    );
  }
}
