import 'dart:async';

import 'package:chronoapp/core/widgets/main_navigation_bar.dart';
import 'package:chronoapp/features/calendar/presentation/pages/calendar_search_page.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_filter_bottom_sheet.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/event_list.dart';
import 'package:flutter/material.dart';
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

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CalendarFilterBottomSheet(),
    );
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
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
        ref.read(calendarLocalFiltersProvider.notifier).initializeFromProfile(profile);
      });
    });

    final showSearchResults = _debouncedSearchQuery.isNotEmpty;
    final mediaPadding = MediaQuery.paddingOf(context);
    final filters = ref.watch(calendarLocalFiltersProvider);
    final hasActiveSearchFilters =
        filters.choir != null || filters.voice != null || filters.className != null;
    // Overlay: SafeArea + 8 + Toolbar + optionale Chip-Zeile + 8
    const chipRowExtent = 48.0;
    final searchBarBottomInset = mediaPadding.top +
        8 +
        kToolbarHeight +
        (hasActiveSearchFilters ? chipRowExtent : 0) +
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
                    onFilterPressed: _openFilters,
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
            onFilterPressed: _openFilters,
          ),
        ],
      ),
    );
  }
}
