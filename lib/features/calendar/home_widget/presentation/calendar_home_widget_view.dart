import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_tokens.dart';
import '../../presentation/widgets/event_list/cards/calendar_entry_card.dart';
import '../../presentation/widgets/search_results/calendar_day_section_header.dart';
import '../domain/calendar_home_widget_layout.dart';

/// Flutter-Render-Baum für das Homescreen-Widget (Search-Page-Optik).
class CalendarHomeWidgetView extends StatelessWidget {
  const CalendarHomeWidgetView({
    required this.rows,
    required this.size,
    required this.useDarkTheme,
    required this.devicePixelRatio,
    super.key,
  });

  final List<CalendarHomeWidgetRow> rows;
  final Size size;
  final bool useDarkTheme;
  final double devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    final theme = useDarkTheme ? AppTheme.dark : AppTheme.light;
    final brightness = useDarkTheme ? Brightness.dark : Brightness.light;

    return MediaQuery(
      data: MediaQueryData(
        size: size,
        platformBrightness: brightness,
        textScaler: TextScaler.noScaling,
        devicePixelRatio: devicePixelRatio,
      ),
      child: Theme(
        data: theme,
        child: Localizations(
          locale: const Locale('de'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: ColoredBox(
                color: theme.colorScheme.surface,
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          'Keine Termine',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            _CalendarHomeWidgetRowView(row: rows[i]),
                            if (i != rows.length - 1)
                              const SizedBox(height: AppSpacing.m),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarHomeWidgetRowView extends StatelessWidget {
  const _CalendarHomeWidgetRowView({required this.row});

  final CalendarHomeWidgetRow row;

  @override
  Widget build(BuildContext context) {
    return switch (row.kind) {
      CalendarHomeWidgetRowKind.header => CalendarDaySectionHeader(
        day: row.day!,
        height: CalendarHomeWidgetLayout.dayHeaderHeight,
      ),
      CalendarHomeWidgetRowKind.entry => CalendarEntryCard(
        entry: row.entry!,
        applyPastStyling: true,
        homeWidgetSnapshot: true,
      ),
    };
  }
}

/// Wrapper für [renderFlutterWidget] mit bestehendem Riverpod-Container.
class CalendarHomeWidgetRenderRoot extends StatelessWidget {
  const CalendarHomeWidgetRenderRoot({
    required this.container,
    required this.child,
    super.key,
  });

  final ProviderContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: child,
    );
  }
}
