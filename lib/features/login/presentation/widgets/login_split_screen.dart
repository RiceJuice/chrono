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
    this.gap = 28,
    this.padding = const EdgeInsets.all(24),
    this.visualBorderRadius = const BorderRadius.all(Radius.circular(32)),
  });

  static const double defaultBreakpoint = 900;

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
        if (constraints.maxWidth < breakpoint) {
          return child;
        }

        final visualPane = Expanded(
          flex: visualFlex,
          child: ClipRRect(
            borderRadius: visualBorderRadius,
            child: visual ?? const LoginSplitPlaceholderVisual(),
          ),
        );

        final contentPane = Expanded(
          flex: contentFlex,
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

class LoginSplitPlaceholderVisual extends StatelessWidget {
  const LoginSplitPlaceholderVisual({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.95),
            scheme.secondaryContainer.withValues(alpha: 0.88),
            scheme.tertiaryContainer.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _VisualGlow(
              size: 260,
              color: scheme.primary.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: _VisualGlow(
              size: 320,
              color: scheme.tertiary.withValues(alpha: 0.20),
            ),
          ),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 0.62,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 92,
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualGlow extends StatelessWidget {
  const _VisualGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
