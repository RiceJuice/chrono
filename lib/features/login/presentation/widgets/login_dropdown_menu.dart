import 'dart:math' as math;

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Höhe einer Menüzeile — an typische Login-[InputDecorator]-Höhe angeglichen.
const double kLoginDropdownMenuItemExtent = 52;

/// So viele Einträge sollen gleichzeitig sichtbar sein; darüber hinaus scrollt das Menü.
const int kLoginDropdownMenuMaxVisibleItems = 6;

/// Zusätzlicher Platz für Menü-Innenränder (Material-Liste).
const double _kLoginDropdownMenuChromePadding = 16;

/// Maximale Höhe des geöffneten Menüs: begrenzt sichtbare Zeilen und bleibt unterhalb der Viewport-Höhe.
double loginDropdownMenuMaxHeight(
  BuildContext context, {
  int maxVisibleItems = kLoginDropdownMenuMaxVisibleItems,
  double itemExtent = kLoginDropdownMenuItemExtent,
}) {
  final double byRows =
      maxVisibleItems * itemExtent + _kLoginDropdownMenuChromePadding;
  final double byScreen = MediaQuery.sizeOf(context).height * 0.38;
  return math.min(byRows, byScreen);
}

MenuStyle loginDropdownMenuSurfaceStyle() {
  return MenuStyle(
    alignment: AlignmentDirectional.topStart,
    backgroundColor: const WidgetStatePropertyAll<Color>(Color(0xFF121212)),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    shadowColor: WidgetStatePropertyAll<Color>(Colors.black.withValues(alpha: 0.45)),
    elevation: const WidgetStatePropertyAll<double>(8),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
    ),
  );
}

List<DropdownMenuEntry<T>> loginDropdownMenuEntries<T>(
  Iterable<T> values, {
  required double width,
  required String Function(T value) labelOf,
  double itemExtent = kLoginDropdownMenuItemExtent,
}) {
  return [
    for (final T v in values)
      DropdownMenuEntry<T>(
        value: v,
        label: labelOf(v),
        style: MenuItemButton.styleFrom(
          fixedSize: Size(width, itemExtent),
          padding: AppInsets.inputContent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15),
          backgroundColor: Colors.transparent,
          alignment: Alignment.centerLeft,
        ),
      ),
  ];
}
