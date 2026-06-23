import 'dart:async';

import 'package:chronoapp/features/calendar/presentation/pages/calendar_search_page.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search_results/calendar_search_active_filters_bar.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search/calendar_search_entrance_transition.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/widgets/app_hairline_divider.dart';
import '../../../../../core/widgets/domspatzen_icon_metrics.dart';

/// Metriken für den fixierten Such-Header (Titel + Filter-Chips).
abstract final class CalendarSearchLayerMetrics {
  static const double titleBlockHeight = 44;
  static const double filtersBlockHeight = 38;

  static const double hairlineHeight = 1;

  static double pinnedHeaderHeight(CalendarFiltersState filters) {
    var height = titleBlockHeight + hairlineHeight;
    if (filters.hasVisibleDeviationChips) {
      height += filtersBlockHeight;
    }
    return height;
  }
}

class CalendarSearchLayer extends ConsumerStatefulWidget {
  const CalendarSearchLayer({
    required this.onClose,
    this.entranceAnimation,
    super.key,
  });

  final VoidCallback onClose;
  final Animation<double>? entranceAnimation;

  @override
  ConsumerState<CalendarSearchLayer> createState() => _CalendarSearchLayerState();
}

class _CalendarSearchLayerState extends ConsumerState<CalendarSearchLayer> {
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  Timer? _debounceTimer;
  String _debouncedSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _onSearchQueryChanged(ref.read(calendarSearchQueryProvider));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchQueryChanged(String nextQuery) {
    final trimmedQuery = nextQuery.trim();
    _debounceTimer?.cancel();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _debouncedSearchQuery = '';
      });
      return;
    }

    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      setState(() {
        _debouncedSearchQuery = trimmedQuery;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(calendarSearchQueryProvider, (previous, next) {
      _onSearchQueryChanged(next);
    });

    final scheme = Theme.of(context).colorScheme;
    final filters = ref.watch(searchFiltersProvider);
    final filtersNotifier = ref.read(searchFiltersProvider.notifier);
    final sparrowSize = DomspatzenIconMetrics.assetSizeForGlyph(22);
    final pinnedHeaderHeight = CalendarSearchLayerMetrics.pinnedHeaderHeight(
      filters,
    );
    final entrance = widget.entranceAnimation;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(dismissAppKeyboard());
        widget.onClose();
      },
      child: Material(
        color: scheme.surface,
        child: SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: pinnedHeaderHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: CalendarSearchPage(
                  query: _debouncedSearchQuery,
                  playInitialMorph: true,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _SearchPinnedHeader(
                  scheme: scheme,
                  sparrowSize: sparrowSize,
                  filters: filters,
                  entranceAnimation: entrance,
                  reduceMotion: reduceMotion,
                  onClearFilters: filtersNotifier.resetToDefaults,
                  onRemoveChoir: filtersNotifier.removeChoir,
                  onRemoveVoice: filtersNotifier.removeVoice,
                  onRemoveClass: filtersNotifier.removeClassName,
                  onRemoveSchoolTrack: filtersNotifier.removeSchoolTrack,
                  onRemoveDiet: filtersNotifier.removeDiet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPinnedHeader extends StatelessWidget {
  const _SearchPinnedHeader({
    required this.scheme,
    required this.sparrowSize,
    required this.filters,
    required this.onClearFilters,
    required this.onRemoveChoir,
    required this.onRemoveVoice,
    required this.onRemoveClass,
    required this.onRemoveSchoolTrack,
    required this.onRemoveDiet,
    this.entranceAnimation,
    this.reduceMotion = false,
  });

  final ColorScheme scheme;
  final double sparrowSize;
  final CalendarFiltersState filters;
  final VoidCallback onClearFilters;
  final ValueChanged<String> onRemoveChoir;
  final ValueChanged<String> onRemoveVoice;
  final ValueChanged<String> onRemoveClass;
  final ValueChanged<String> onRemoveSchoolTrack;
  final ValueChanged<String> onRemoveDiet;
  final Animation<double>? entranceAnimation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            'Suchen',
            style: GoogleFonts.libreBaskerville(
              textStyle: Theme.of(context).textTheme.headlineLarge,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Opacity(
            opacity: 0.32,
            child: SvgPicture.asset(
              DomspatzenIconMetrics.assetPath,
              height: sparrowSize,
              width: sparrowSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );

    final filtersRow = CalendarSearchActiveFiltersBar(
      filters: filters,
      onClearFilters: onClearFilters,
      onRemoveChoir: onRemoveChoir,
      onRemoveVoice: onRemoveVoice,
      onRemoveClass: onRemoveClass,
      onRemoveSchoolTrack: onRemoveSchoolTrack,
      onRemoveDiet: onRemoveDiet,
    );

    final animatedTitle = entranceAnimation == null
        ? titleRow
        : CalendarSearchEntranceTransition.titleRow(
            animation: entranceAnimation!,
            reduceMotion: reduceMotion,
            child: titleRow,
          );
    final animatedFilters = entranceAnimation == null
        ? filtersRow
        : CalendarSearchEntranceTransition.filtersRow(
            animation: entranceAnimation!,
            reduceMotion: reduceMotion,
            child: filtersRow,
          );

    return Material(
      color: scheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          animatedTitle,
          animatedFilters,
          const AppHairlineDivider.horizontal(),
        ],
      ),
    );
  }
}

/// Blendet die Tastatur kontrolliert aus, bevor native/Flutter-Textfelder
/// abgebaut werden — vermeidet HardwareKeyboard-Assertions (v. a. Simulator).
Future<void> dismissAppKeyboard() async {
  final focus = FocusManager.instance.primaryFocus;
  if (focus != null && focus.hasFocus) {
    focus.unfocus();
  }
  try {
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  } catch (_) {
    // Ignorieren, falls kein aktiver Text-Input-Client existiert.
  }
}

const _calendarPath = '/calendar';

/// Entspricht [kMainShellNavigationBarHeight] — hier dupliziert, um Zirkelimporte zu vermeiden.
const _mainShellNavigationBarHeight = 56.0;

/// Speichert die globale Position eines Widgets als Morph-Startpunkt der Lupe.
void captureCalendarSearchMorphOrigin(WidgetRef ref, BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return;
  ref
      .read(calendarSearchMorphOriginProvider.notifier)
      .set(box.localToGlobal(Offset.zero) & box.size);
}

/// Geschätzte Tab-Lupen-Position (iOS [CNTabBar], wenn kein RenderBox verfügbar).
void estimateCalendarSearchMorphOrigin(WidgetRef ref, BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  const buttonSize = 44.0;
  const trailingInset = 8.0;
  final top = size.height -
      padding.bottom -
      _mainShellNavigationBarHeight +
      (_mainShellNavigationBarHeight - buttonSize) / 2;
  ref.read(calendarSearchMorphOriginProvider.notifier).set(
        Rect.fromLTWH(
          size.width - trailingInset - buttonSize,
          top,
          buttonSize,
          buttonSize,
        ),
      );
}

/// Verlässt die Suche, wechselt zum Kalender-Tab und blendet die Wochen-Zeile
/// im Header ein.
void exitCalendarSearchToCalendarTab(
  WidgetRef ref,
  BuildContext context, {
  CNTabBarSearchController? searchController,
}) {
  closeCalendarSearchMode(ref, searchController: searchController);
  ref.read(calendarHeaderWeekExpandRequestProvider.notifier).request();

  final location = GoRouterState.of(context).uri.path;
  if (!location.startsWith(_calendarPath)) {
    context.go(_calendarPath);
  }
}

/// Öffnet den Flutter-Suchmodus nach Tap auf die native iOS-Tab-Lupe.
///
/// Klappt die native Tab-Bar-Such-Morph sofort ein, damit nur
/// [CalendarSearchBottomBar] (Liquid Glass) sichtbar bleibt.
void openCalendarSearchFromNativeTab(
  WidgetRef ref, {
  required CNTabBarSearchController searchController,
  BuildContext? morphContext,
}) {
  AppHaptics.light();
  if (morphContext != null) {
    estimateCalendarSearchMorphOrigin(ref, morphContext);
  }
  ref.read(calendarSearchOpenProvider.notifier).open();

  ref.read(calendarSearchNativeCollapseGuardProvider.notifier).arm();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (searchController.isActive) {
      searchController.deactivateSearch();
    }
    ref.read(calendarSearchNativeCollapseGuardProvider.notifier).disarm();
  });
}

/// Schließt den Suchmodus und setzt zugehörigen State zurück.
///
/// [deactivateNativeSearch]: `false`, wenn iOS die native Suche bereits
/// eingeklappt hat ([CNTabBarSearchItem.onSearchActiveChanged] mit `false`).
void closeCalendarSearchMode(
  WidgetRef ref, {
  CNTabBarSearchController? searchController,
  bool deactivateNativeSearch = true,
}) {
  if (!ref.read(calendarSearchOpenProvider)) {
    return;
  }

  unawaited(dismissAppKeyboard());

  ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
  ref.read(calendarSearchQueryProvider.notifier).clear();
  ref.read(searchFiltersProvider.notifier).resetToDefaults();
  ref.read(calendarSearchMorphOriginProvider.notifier).clear();
  ref.read(calendarSearchOpenProvider.notifier).close();

  if (!deactivateNativeSearch || searchController == null) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (searchController.isActive) {
      searchController.deactivateSearch();
    }
    searchController.clear(deactivate: false);
  });
}
