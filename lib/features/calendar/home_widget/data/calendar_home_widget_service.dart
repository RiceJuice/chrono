import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../../core/time/app_date_time.dart';
import '../../domain/models/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../presentation/providers/calendar_providers.dart';
import '../../live_activity/live_activity_constants.dart';
import '../domain/calendar_home_widget_constants.dart';
import '../domain/calendar_home_widget_layout.dart';
import '../../presentation/widgets/search_results/search_results_sections.dart';
import '../presentation/calendar_home_widget_view.dart';

class CalendarHomeWidgetService {
  CalendarHomeWidgetService({required CalendarRepository repository})
    : _repository = repository;

  final CalendarRepository _repository;

  static bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await HomeWidget.setAppGroupId(kLiveActivityAppGroupId);
    _initialized = true;
  }

  Future<List<CalendarEntry>> loadUpcomingFilteredEntries({
    required CalendarFiltersState filters,
  }) async {
    final today = AppDateTime.todayLocal();
    final endExclusive = today.add(
      const Duration(days: kCalendarHomeWidgetDayHorizon),
    );
    final entries = await _repository
        .watchEntriesInLocalRange(
          startInclusive: today,
          endExclusive: endExclusive,
        )
        .first;
    return CalendarHomeWidgetLayout.filterEntries(
      entries: entries,
      filters: filters,
    );
  }

  Future<double> _resolvePixelRatio() async {
    if (Platform.isAndroid) {
      final density = await HomeWidget.getWidgetData<double>(
        kCalendarHomeWidgetAndroidDensityKey,
      );
      if (density != null && density > 0) {
        return density;
      }
    }
    final view = PlatformDispatcher.instance.views.firstOrNull;
    return view?.devicePixelRatio ?? 3;
  }

  Future<void> _renderTarget({
    required ProviderContainer container,
    required SearchResultsSections sections,
    required CalendarHomeWidgetRenderTarget target,
    required double pixelRatio,
  }) async {
    final rows = CalendarHomeWidgetLayout.buildFittedRows(
      sectionsResult: sections,
      maxHeight: target.logicalSize.height,
    );

    for (final isDark in const [false, true]) {
      final view = CalendarHomeWidgetRenderRoot(
        container: container,
        child: CalendarHomeWidgetView(
          rows: rows,
          size: target.logicalSize,
          useDarkTheme: isDark,
          devicePixelRatio: pixelRatio,
        ),
      );

      try {
        await HomeWidget.renderFlutterWidget(
          view,
          key: target.imageKey(isDark: isDark),
          logicalSize: target.logicalSize,
          pixelRatio: pixelRatio,
          appGroupId: kLiveActivityAppGroupId,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[HomeWidget] render ${target.imageKey(isDark: isDark)} failed: $e\n$st',
          );
        }
      }
    }
  }

  Future<void> renderAndUpdate({
    required ProviderContainer container,
    required List<CalendarHomeWidgetRenderTarget> targets,
  }) async {
    await ensureInitialized();

    final filters = container.read(calendarFiltersProvider);
    final entries = await loadUpcomingFilteredEntries(filters: filters);
    final sections = CalendarHomeWidgetLayout.buildSectionsFromEntries(
      entries: entries,
    );
    final pixelRatio = await _resolvePixelRatio();

    for (final target in targets) {
      await _renderTarget(
        container: container,
        sections: sections,
        target: target,
        pixelRatio: pixelRatio,
      );
    }

    await HomeWidget.updateWidget(
      name: kCalendarHomeWidgetIosName,
      iOSName: kCalendarHomeWidgetIosName,
      androidName: kCalendarHomeWidgetAndroidName,
    );

    if (!Platform.isAndroid) return;

    final widthDp = await HomeWidget.getWidgetData<int>(
      kCalendarHomeWidgetAndroidWidthDpKey,
    );
    final heightDp = await HomeWidget.getWidgetData<int>(
      kCalendarHomeWidgetAndroidHeightDpKey,
    );
    final usedAndroidTarget = targets.any((t) => t.sizeToken == 'android');
    if (!usedAndroidTarget &&
        widthDp != null &&
        heightDp != null &&
        widthDp > 0 &&
        heightDp > 0) {
      final androidTarget = CalendarHomeWidgetRenderTarget.android(
        widthDp: widthDp.toDouble(),
        heightDp: heightDp.toDouble(),
      );
      await _renderTarget(
        container: container,
        sections: sections,
        target: androidTarget,
        pixelRatio: pixelRatio,
      );
      await HomeWidget.updateWidget(
        name: kCalendarHomeWidgetIosName,
        iOSName: kCalendarHomeWidgetIosName,
        androidName: kCalendarHomeWidgetAndroidName,
      );
    }
  }

  Future<List<CalendarHomeWidgetRenderTarget>> resolveRenderTargets() async {
    await ensureInitialized();

    if (Platform.isAndroid) {
      final widthDp = await HomeWidget.getWidgetData<int>(
        kCalendarHomeWidgetAndroidWidthDpKey,
      );
      final heightDp = await HomeWidget.getWidgetData<int>(
        kCalendarHomeWidgetAndroidHeightDpKey,
      );
      if (widthDp != null &&
          heightDp != null &&
          widthDp > 0 &&
          heightDp > 0) {
        return [
          CalendarHomeWidgetRenderTarget.android(
            widthDp: widthDp.toDouble(),
            heightDp: heightDp.toDouble(),
          ),
        ];
      }
    }

    final installed = await HomeWidget.getInstalledWidgets();
    if (installed.isEmpty) {
      return const [
        CalendarHomeWidgetRenderTarget.medium,
        CalendarHomeWidgetRenderTarget.large,
      ];
    }

    final targets = <CalendarHomeWidgetRenderTarget>{};
    for (final info in installed) {
      final family = info.iOSFamily?.toLowerCase();
      if (family == 'large') {
        targets.add(CalendarHomeWidgetRenderTarget.large);
      } else if (family == 'medium') {
        targets.add(CalendarHomeWidgetRenderTarget.medium);
      } else if (info.androidWidgetId != null) {
        targets.add(CalendarHomeWidgetRenderTarget.medium);
        targets.add(CalendarHomeWidgetRenderTarget.large);
      }
    }

    return targets.isEmpty
        ? const [
            CalendarHomeWidgetRenderTarget.medium,
            CalendarHomeWidgetRenderTarget.large,
          ]
        : targets.toList(growable: false);
  }
}

final calendarHomeWidgetServiceProvider = Provider<CalendarHomeWidgetService>((
  ref,
) {
  return CalendarHomeWidgetService(
    repository: ref.watch(calendarRepositoryProvider),
  );
});
