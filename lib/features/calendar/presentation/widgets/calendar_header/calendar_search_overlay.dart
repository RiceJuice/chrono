import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  void didUpdateWidget(covariant CalendarSearchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isOpen && widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isOpen) return;
        _searchFocusNode.requestFocus();
      });
    }

    if (oldWidget.isOpen && !widget.isOpen) {
      _searchFocusNode.unfocus();
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        widget.onQueryChanged('');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(calendarLocalFiltersProvider);
    final filtersNotifier = ref.read(calendarLocalFiltersProvider.notifier);

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: widget.isOpen ? Offset.zero : const Offset(0, -1.2),
          child: Material(
            elevation: 3,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.search,
                                onChanged: widget.onQueryChanged,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText: 'Suchen...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onFilterPressed,
                              tooltip: 'Filter',
                              icon: const Icon(Icons.tune),
                            ),
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.onQueryChanged('');
                                widget.onClose();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      _SearchOverlayActiveFiltersBar(
                        filters: filters,
                        onRemoveChoir: () => filtersNotifier.setChoir(null),
                        onRemoveVoice: () => filtersNotifier.setVoice(null),
                        onRemoveClass: () => filtersNotifier.setClassName(null),
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
    required this.onRemoveChoir,
    required this.onRemoveVoice,
    required this.onRemoveClass,
  });

  final CalendarLocalFilters filters;
  final VoidCallback onRemoveChoir;
  final VoidCallback onRemoveVoice;
  final VoidCallback onRemoveClass;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filters.choir != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('Chor: ${_formatFilterChipValue(filters.choir!)}'),
            onDeleted: onRemoveChoir,
          ),
        ),
      );
    }
    if (filters.voice != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('Stimme: ${_formatFilterChipValue(filters.voice!)}'),
            onDeleted: onRemoveVoice,
          ),
        ),
      );
    }
    if (filters.className != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text('Klasse: ${_formatFilterChipValue(filters.className!)}'),
            onDeleted: onRemoveClass,
          ),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
}

String _formatFilterChipValue(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
