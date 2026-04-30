import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chronoapp/core/database/backend_enums.dart';

import '../../providers/calendar_providers.dart';

class CalendarSearchOverlay extends ConsumerStatefulWidget {
  const CalendarSearchOverlay({
    required this.isOpen,
    required this.onClose,
    required this.onQueryChanged,
    required this.onFilterPressed,
    super.key,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onFilterPressed;

  @override
  ConsumerState<CalendarSearchOverlay> createState() =>
      _CalendarSearchOverlayState();
}

class _CalendarSearchOverlayState extends ConsumerState<CalendarSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    if (!mounted) return;
    ref
        .read(calendarSearchInputFocusedProvider.notifier)
        .update(_searchFocusNode.hasFocus);
    setState(() {});
  }

  void _handleQueryChanged(String value) {
    widget.onQueryChanged(value);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant CalendarSearchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOpen && !widget.isOpen) {
      _searchFocusNode.unfocus();
      ref.read(calendarSearchInputFocusedProvider.notifier).dismiss();
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        widget.onQueryChanged('');
      }
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inputTheme = theme.inputDecorationTheme;
    final searchTextColor = scheme.onSurface.withOpacity(0.96);
    final searchHintAndIconColor = scheme.onSurface.withOpacity(0.7);
    final searchBackgroundColor = scheme.brightness == Brightness.dark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.12),
            scheme.surfaceContainer,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.10),
            scheme.surfaceContainer,
          );
    const searchIconAndTextSize = 16.0;

    final filters = ref.watch(searchFiltersProvider);
    final filtersNotifier = ref.read(searchFiltersProvider.notifier);
    final isSearchFocused = ref.watch(calendarSearchInputFocusedProvider);

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: widget.isOpen ? Offset.zero : const Offset(0, -1.2),
          child: Material(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainer,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 42,
                        child: Center(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (isSearchFocused) {
                                    _searchFocusNode.unfocus();
                                    return;
                                  }
                                  _searchController.clear();
                                  widget.onQueryChanged('');
                                  widget.onClose();
                                },
                                icon: isSearchFocused
                                    ? const Icon(
                                        Icons.close_rounded,
                                        key: ValueKey('close-search-focus'),
                                        size: 22,
                                      )
                                    : const Icon(
                                        Icons.chevron_left_rounded,
                                        key: ValueKey('close-search-overlay'),
                                        size: 28,
                                      ),
                                style: const ButtonStyle(
                                  animationDuration: Duration.zero,
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.zero,
                                  ),
                                  minimumSize: WidgetStatePropertyAll(
                                    Size(38, 38),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  textInputAction: TextInputAction.search,
                                  onChanged: _handleQueryChanged,
                                  style: TextStyle(
                                    fontSize: searchIconAndTextSize,
                                    color: searchTextColor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: searchBackgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: 18,
                                      color: searchHintAndIconColor,
                                    ),
                                    prefixIconConstraints:
                                        const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                    hintText: 'Finde den richtigen Termin',
                                    hintStyle:
                                        (inputTheme.hintStyle ?? const TextStyle())
                                            .copyWith(
                                              fontSize: searchIconAndTextSize,
                                              color: searchHintAndIconColor,
                                            ),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                _searchController.clear();
                                                _handleQueryChanged('');
                                              },
                                              icon: Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: theme.colorScheme
                                                    .surfaceContainerHighest,
                                              ),
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                      searchHintAndIconColor,
                                                    ),
                                                padding:
                                                    const WidgetStatePropertyAll(
                                                      EdgeInsets.zero,
                                                    ),
                                                minimumSize:
                                                    const WidgetStatePropertyAll(
                                                      Size(18, 18),
                                                    ),
                                                maximumSize:
                                                    const WidgetStatePropertyAll(
                                                      Size(18, 18),
                                                    ),
                                                shape:
                                                    const WidgetStatePropertyAll(
                                                      CircleBorder(),
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ),
                                    suffixIconConstraints:
                                        const BoxConstraints(
                                          minWidth: 26,
                                          minHeight: 22,
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: widget.onFilterPressed,
                                tooltip: 'Filter',
                                icon: const Icon(Icons.filter_list_rounded),
                                style: const ButtonStyle(
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.zero,
                                  ),
                                  minimumSize: WidgetStatePropertyAll(
                                    Size(36, 36),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SearchOverlayActiveFiltersBar(
                        filters: filters,
                        onClearFilters: filtersNotifier.resetToDefaults,
                        onRemoveChoir: (value) =>
                            filtersNotifier.removeChoir(value),
                        onRemoveVoice: (value) =>
                            filtersNotifier.removeVoice(value),
                        onRemoveClass: (value) =>
                            filtersNotifier.removeClassName(value),
                        onRemoveSchoolTrack: (value) =>
                            filtersNotifier.removeSchoolTrack(value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchOverlayActiveFiltersBar extends StatelessWidget {
  const _SearchOverlayActiveFiltersBar({
    required this.filters,
    required this.onClearFilters,
    required this.onRemoveChoir,
    required this.onRemoveVoice,
    required this.onRemoveClass,
    required this.onRemoveSchoolTrack,
  });

  final CalendarFiltersState filters;
  final VoidCallback onClearFilters;
  final ValueChanged<String> onRemoveChoir;
  final ValueChanged<String> onRemoveVoice;
  final ValueChanged<String> onRemoveClass;
  final ValueChanged<String> onRemoveSchoolTrack;

  @override
  Widget build(BuildContext context) {
    if (!filters.hasVisibleDeviationChips) {
      return const SizedBox.shrink();
    }


    final chips = <Widget>[];

    chips.add(
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: SizedBox.square(
          dimension: 30,
          child: InputChip(
            tooltip: 'Alle Filter löschen',
            label: const Icon(Icons.close_rounded, size: 16),
            shape: const CircleBorder(),
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () => _handleChipInteraction(onClearFilters),
          ),
        ),
      ),
    );

    for (final choir in filters.choirDeviations) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InputChip(
            label: Text('Chor: ${_formatFilterChipValue(choir)}'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onDeleted: () => _handleChipInteraction(() => onRemoveChoir(choir)),
          ),
        ),
      );
    }
    for (final voice in filters.voiceDeviations) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InputChip(
            label: Text('Stimme: ${_formatFilterChipValue(voice)}'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onDeleted: () => _handleChipInteraction(() => onRemoveVoice(voice)),
          ),
        ),
      );
    }
    for (final className in filters.classNameDeviations) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InputChip(
            label: Text('Klasse: ${_formatFilterChipValue(className)}'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onDeleted: () =>
                _handleChipInteraction(() => onRemoveClass(className)),
          ),
        ),
      );
    }
    for (final schoolTrack in filters.schoolTrackDeviations) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InputChip(
            label: Text(
              'Schulzweig: ${_formatSchoolTrackFilterChipValue(schoolTrack)}',
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onDeleted: () =>
                _handleChipInteraction(() => onRemoveSchoolTrack(schoolTrack)),
          ),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: chips,
          ),
        ),
      ),
    );
  }

  void _handleChipInteraction(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }
}

String _formatFilterChipValue(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _formatSchoolTrackFilterChipValue(String value) {
  final schoolTrack = BackendSchoolTrackCodec.fromBackend(value);
  if (schoolTrack != BackendSchoolTrack.unknown) {
    return schoolTrack.displayLabel;
  }
  return _formatFilterChipValue(value);
}
