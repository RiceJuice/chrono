import 'dart:async';

import 'package:chronoapp/features/calendar/presentation/pages/calendar_search_page.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/search_results/calendar_search_active_filters_bar.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/widgets/domspatzen_icon_metrics.dart';

class CalendarSearchLayer extends ConsumerStatefulWidget {
  const CalendarSearchLayer({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
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
              ),
              CalendarSearchActiveFiltersBar(
                filters: filters,
                onClearFilters: filtersNotifier.resetToDefaults,
                onRemoveChoir: filtersNotifier.removeChoir,
                onRemoveVoice: filtersNotifier.removeVoice,
                onRemoveClass: filtersNotifier.removeClassName,
                onRemoveSchoolTrack: filtersNotifier.removeSchoolTrack,
                onRemoveDiet: filtersNotifier.removeDiet,
              ),
              Expanded(
                child: CalendarSearchPage(
                  query: _debouncedSearchQuery,
                  playInitialMorph: true,
                ),
              ),
            ],
          ),
        ),
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
