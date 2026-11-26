import 'login_photo_carousel.dart';
import 'login_tablet_layout.dart';

import 'package:flutter/material.dart';

enum LoginSplitVisualSide { left, right }

/// Wiederverwendbare Desktop-Huelle fuer den Login-Flow.
///
/// [child] enthaelt den vollstaendigen Login-Inhalt inklusive Top-Bar und
/// Step-Indikator. [visual] ist austauschbar, damit spaeter echte Bilder,
/// andere Groessen oder die Seite des Bildbereichs konfiguriert werden koennen.
class LoginSplitScreen extends StatelessWidget {
  const LoginSplitScreen({
    super.key,
    required this.child,
    this.visual,
    this.visualSide = LoginSplitVisualSide.right,
    this.breakpoint = defaultBreakpoint,
    this.contentFlex = 5,
    this.visualFlex = 6,
    this.contentMaxWidth = 560,
    this.gap = 0,
    this.padding = EdgeInsets.zero,
    this.visualBorderRadius = BorderRadius.zero,
  });

  static const double defaultBreakpoint = 700;

  final Widget child;
  final Widget? visual;
  final LoginSplitVisualSide visualSide;
  final double breakpoint;
  final int contentFlex;
  final int visualFlex;
  final double contentMaxWidth;
  final double gap;
  final EdgeInsetsGeometry padding;
  final BorderRadius visualBorderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (LoginTabletLayout.isTablet(context) ||
            constraints.maxWidth < breakpoint) {
          return child;
        }

        final visualPane = Expanded(
          flex: constraints.maxWidth < 900 ? 4 : visualFlex,
          child: ClipRRect(
            borderRadius: visualBorderRadius,
            child: visual ?? const LoginPhotoCarousel(),
          ),
        );

        final contentPane = Expanded(
          flex: constraints.maxWidth < 900 ? 6 : contentFlex,
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: child,
            ),
          ),
        );

        final children = visualSide == LoginSplitVisualSide.left
            ? <Widget>[visualPane, SizedBox(width: gap), contentPane]
            : <Widget>[contentPane, SizedBox(width: gap), visualPane];

        return Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}
