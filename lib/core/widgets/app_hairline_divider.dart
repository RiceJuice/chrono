import 'package:flutter/material.dart';

/// iOS/Apple-style hairline divider.
///
/// - Dark mode: white with 15% opacity (Apple system divider)
/// - Thickness: exactly 1 physical pixel (uses devicePixelRatio)
class AppHairlineDivider extends StatelessWidget {
  const AppHairlineDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  const AppHairlineDivider.horizontal({
    super.key,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : axis = Axis.horizontal;

  const AppHairlineDivider.vertical({
    super.key,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  }) : axis = Axis.vertical;

  final Axis axis;
  final Color? color;
  final double indent;
  final double endIndent;

  static Color defaultColorFor(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return const Color(0xFFFFFFFF).withValues(alpha: 0.15);
    }
    return theme.colorScheme.onSurface.withValues(alpha: 0.10);
  }

  static double physicalPixel(BuildContext context) {
    final dpr =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? View.of(context).devicePixelRatio;
    if (dpr <= 0) return 1.0;
    return 1.0 / dpr;
  }

  static BorderSide borderSide(BuildContext context, Color color) {
    return BorderSide(color: color, width: physicalPixel(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? defaultColorFor(theme);
    final thickness = physicalPixel(context);

    if (axis == Axis.horizontal) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          start: indent,
          end: endIndent,
        ),
        child: SizedBox(
          width: double.infinity,
          height: thickness,
          child: ColoredBox(color: resolvedColor),
        ),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: indent,
        bottom: endIndent,
      ),
      child: SizedBox(
        width: thickness,
        height: double.infinity,
        child: ColoredBox(color: resolvedColor),
      ),
    );
  }
}

