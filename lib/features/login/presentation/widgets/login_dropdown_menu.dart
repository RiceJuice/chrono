import 'dart:math' as math;

import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

DateTime? _lastLoginDropdownSelectionHapticAt;

/// Ein kurzes [HapticFeedback.selectionClick] bei Dropdown-Auswahl — mit Debounce,
/// falls [DropdownMenu.onSelected] kurz zweimal ausgelöst wird.
void loginDropdownSelectionHaptic() {
  final DateTime now = DateTime.now();
  final DateTime? last = _lastLoginDropdownSelectionHapticAt;
  if (last != null &&
      now.difference(last) < const Duration(milliseconds: 320)) {
    return;
  }
  _lastLoginDropdownSelectionHapticAt = now;
  HapticFeedback.selectionClick();
}

/// Unsichtbarer [prefixIcon]-Listener: bei „Menü offen“ (Tap auf Feld oder Pfeil).
/// Nutzt [HapticFeedback.lightImpact], damit es sich nicht wie ein zweites
/// [selectionClick] bei der anschließenden Auswahl anfühlt.
InputDecoration loginDropdownDecorationWithOpenHaptic(InputDecoration decoration) {
  return decoration.copyWith(
    prefixIcon: const _LoginDropdownMenuOpenHapticHost(),
    prefixIconConstraints: const BoxConstraints(
      minWidth: 0,
      maxWidth: 0,
      minHeight: 0,
      maxHeight: 0,
    ),
  );
}

class _LoginDropdownMenuOpenHapticHost extends StatefulWidget {
  const _LoginDropdownMenuOpenHapticHost();

  @override
  State<_LoginDropdownMenuOpenHapticHost> createState() =>
      _LoginDropdownMenuOpenHapticHostState();
}

class _LoginDropdownMenuOpenHapticHostState extends State<_LoginDropdownMenuOpenHapticHost> {
  bool? _wasOpen;

  @override
  Widget build(BuildContext context) {
    final bool now = MenuController.maybeIsOpenOf(context) ?? false;
    if (_wasOpen == false && now) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HapticFeedback.lightImpact();
      });
    }
    _wasOpen = now;
    return const SizedBox.shrink();
  }
}

/// Maximal gleichzeitig sichtbare Einträge; darüber hinaus scrollt das Menü.
const int kLoginDropdownMaxVisibleItems = 6;

/// Zeilenhöhe im Menü — an [InputDecorationTheme.contentPadding] und
/// [TextTheme.bodyLarge] der aktuellen Theme angeglichen (wie der sichtbare Kasten).
double loginDropdownMenuItemExtentFor(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final EdgeInsets resolved =
      theme.inputDecorationTheme.contentPadding?.resolve(
        Directionality.of(context),
      ) ??
      AppInsets.inputContent;
  final TextStyle? body = theme.textTheme.bodyLarge;
  final double fontSize = body?.fontSize ?? 16;
  final double lineHeight = body?.height ?? 1.2;
  return math.max(48.0, resolved.vertical + fontSize * lineHeight);
}

/// Obergrenze für die Menühöhe: [maxVisibleItems] Zeilen, zusätzlich
/// begrenzt auf einen Anteil der Bildschirmhöhe, damit das Menü nicht den ganzen Screen füllt.
double loginDropdownMenuMaxHeight(
  BuildContext context, {
  int maxVisibleItems = kLoginDropdownMaxVisibleItems,
  double maxFractionOfScreenHeight = 0.38,
}) {
  final double itemExtent = loginDropdownMenuItemExtentFor(context);
  final double fromRows = maxVisibleItems * itemExtent;
  final double fromScreen =
      MediaQuery.sizeOf(context).height * maxFractionOfScreenHeight;
  return math.min(fromRows, fromScreen);
}

MenuStyle loginDropdownMenuSurfaceStyle(BuildContext context) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return MenuStyle(
    alignment: AlignmentDirectional.topStart,
    backgroundColor: WidgetStatePropertyAll<Color>(scheme.surfaceContainerHighest),
    surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    shadowColor: WidgetStatePropertyAll<Color>(
      scheme.shadow.withValues(alpha: scheme.brightness == Brightness.dark ? 0.45 : 0.18),
    ),
    elevation: const WidgetStatePropertyAll<double>(8),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
    ),
  );
}

List<DropdownMenuEntry<T>> loginDropdownMenuEntries<T>(
  BuildContext context,
  Iterable<T> values, {
  required double width,
  required String Function(T value) labelOf,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final TextStyle? baseBody = Theme.of(context).textTheme.bodyLarge;
  final double itemExtent = loginDropdownMenuItemExtentFor(context);
  final TextStyle itemTextStyle = (baseBody ?? const TextStyle()).copyWith(
    fontSize: 15,
    color: scheme.onSurface,
  );
  return [
    for (final T v in values)
      DropdownMenuEntry<T>(
        value: v,
        label: labelOf(v),
        style: MenuItemButton.styleFrom(
          fixedSize: Size(width, itemExtent),
          padding: AppInsets.inputContent,
          foregroundColor: scheme.onSurface,
          textStyle: itemTextStyle,
          backgroundColor: Colors.transparent,
          alignment: Alignment.centerLeft,
        ),
      ),
  ];
}
