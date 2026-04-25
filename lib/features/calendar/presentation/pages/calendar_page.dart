import 'dart:async';

import 'package:chronoapp/core/widgets/main_navigation_bar.dart';
import 'package:chronoapp/features/calendar/presentation/pages/calendar_search_page.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_filter_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/features/settings/presentation/providers/settings_profile_providers.dart';

import '../widgets/calendar_header/calendar_header.dart';
import '../widgets/calendar_header/calendar_search_overlay.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  bool _isSearchOpen = false;
  Timer? _debounceTimer;
  String _debouncedSearchQuery = '';

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
    });
  }

  Future<void> _openCalendarFilters() async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.calendarSettings,
      ),
    );
  }

  Future<void> _openSearchFilters() async {
    HapticFeedback.heavyImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(
        mode: CalendarFilterBottomSheetMode.searchFilter,
      ),
    );
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
    ref.read(searchFiltersProvider.notifier).resetToDefaults();
    setState(() {
      _isSearchOpen = false;
      _debouncedSearchQuery = '';
    });
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
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncedProfileProvider, (_, next) {
      next.whenData((profile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref
              .read(calendarFiltersProvider.notifier)
              .initializeFromProfile(profile);
        });
      });
    });
    ref.listen<CalendarFiltersState>(calendarFiltersProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref
            .read(searchFiltersProvider.notifier)
            .initializeFromCalendar(next);
      });
    });
    final searchFilters = ref.watch(searchFiltersProvider);
    final hasVisibleSearchFilterChips = searchFilters.hasVisibleDeviationChips;
    final showSearchResults =
        _isSearchOpen ||
        _debouncedSearchQuery.isNotEmpty ||
        searchFilters.hasUserOverrides;
    final mediaPadding = MediaQuery.paddingOf(context);
    // Overlay: SafeArea + 8 + Toolbar + optionale Chip-Zeile + 8
    const chipRowExtent = 48.0;
    final searchBarBottomInset = mediaPadding.top +
        8 +
        kToolbarHeight +
        (_isSearchOpen && hasVisibleSearchFilterChips ? chipRowExtent : 0) +
        8;

    return Scaffold(
      bottomNavigationBar: MainNavigationBar(),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (!showSearchResults) ...[
                  CalendarHeader(
                    onSearchPressed: _openSearch,
                    onFilterPressed: _openCalendarFilters,
                  ),
                  const Divider(),
                  const Expanded(child: EventList()),
                ] else ...[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: searchBarBottomInset),
                      child: CalendarSearchPage(query: _debouncedSearchQuery),
                    ),
                  ),
                ],
              ],
            ),
          ),
          CalendarSearchOverlay(
            isOpen: _isSearchOpen,
            onClose: _closeSearch,
            onQueryChanged: _onSearchQueryChanged,
            onFilterPressed: _openSearchFilters,
          ),
        ],
      ),
    );
  }
}
