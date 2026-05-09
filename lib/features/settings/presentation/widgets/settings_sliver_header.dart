import 'package:flutter/material.dart';

/// Große Seitenüberschrift für die Einstellungen (scrollt mit dem Inhalt).
///
/// Der kompakte Titel in der [AppBar] wird in [SettingsPage] gesteuert, sobald
/// diese Überschrift unter den Balken geschoben wurde.
abstract final class SettingsSliverHeader {
  SettingsSliverHeader._();

  static const title = 'Einstellungen und Präferenzen';

  /// Zwei Zeilen für die große Überschrift unter der AppBar.
  static const largeTitle = 'Einstellungen und\nPräferenzen';

  static Widget largeTitleSliver(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Text(
          largeTitle,
          maxLines: 2,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
