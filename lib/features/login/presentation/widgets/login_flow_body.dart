import 'package:flutter/material.dart';

import '../routes/login_paths.dart';
import 'login_flow_chrome.dart';
import 'login_scroll_surface.dart';

/// Einheitlicher Body für Login-Seiten.
///
/// - **Startscreen** ([pinBottomBarToEdge]): feste untere Leiste, Marke zentriert darüber.
/// - **Schrittseiten**: ein Scrollbereich; Footer und Primärbutton scrollen mit dem Inhalt.
class LoginFlowBody extends StatelessWidget {
  const LoginFlowBody({
    super.key,
    required this.location,
    required this.child,
    this.scrollPadding = EdgeInsets.zero,
    this.bottomBar,
    this.horizontalContentPadding,
    this.includeChrome = true,
    this.fillViewport = true,
    this.pinBottomBarToEdge = false,
  });

  final String location;
  final Widget child;
  final EdgeInsets scrollPadding;
  final Widget? bottomBar;
  final EdgeInsetsGeometry? horizontalContentPadding;
  final bool includeChrome;
  final bool fillViewport;

  /// Startscreen: untere Leiste am Bildschirmrand, kein Scroll im Hauptbereich.
  final bool pinBottomBarToEdge;

  EdgeInsetsGeometry _contentPadding() {
    if (horizontalContentPadding != null) return horizontalContentPadding!;
    final isStart = location == LoginPaths.login;
    final isChoirPage = location == LoginPaths.choir;
    if (isChoirPage || isStart) return EdgeInsets.zero;
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportHeight = constraints.maxHeight;

        if (pinBottomBarToEdge && bottomBar != null) {
          return _LoginPinnedBottomBody(
            includeChrome: includeChrome,
            location: location,
            bottomBar: bottomBar!,
            child: child,
          );
        }

        return LoginScrollSurface(
          scrollPadding: scrollPadding,
          child: _LoginScrollableColumn(
            viewportHeight: fillViewport ? viewportHeight : null,
            includeChrome: includeChrome,
            location: location,
            contentPadding: _contentPadding(),
            child: child,
          ),
        );
      },
    );
  }
}

/// Startscreen: Squircle-Leiste fix unten, Marke füllt den Bereich darüber.
class _LoginPinnedBottomBody extends StatelessWidget {
  const _LoginPinnedBottomBody({
    required this.includeChrome,
    required this.location,
    required this.child,
    required this.bottomBar,
  });

  final bool includeChrome;
  final String location;
  final Widget child;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (includeChrome) LoginFlowChrome(location: location),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ],
          ),
        ),
        bottomBar,
      ],
    );
  }
}

/// Scroll-Inhalt mit optionaler Mindesthöhe (= Viewport), z. B. für zentrierte Abschlussseiten.
class _LoginScrollableColumn extends StatelessWidget {
  const _LoginScrollableColumn({
    required this.includeChrome,
    required this.location,
    required this.child,
    required this.contentPadding,
    this.viewportHeight,
  });

  final bool includeChrome;
  final String location;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;
  final double? viewportHeight;

  @override
  Widget build(BuildContext context) {
    final Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: viewportHeight != null
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (includeChrome) LoginFlowChrome(location: location),
        Padding(
          padding: contentPadding,
          child: child,
        ),
      ],
    );

    final double? minHeight = viewportHeight;
    if (minHeight == null) return column;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: column,
    );
  }
}
