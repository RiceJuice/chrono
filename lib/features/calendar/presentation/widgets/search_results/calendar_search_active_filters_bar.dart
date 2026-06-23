import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontale Filter-Chips unter der Suchleiste im Such-Screen.
class CalendarSearchActiveFiltersBar extends StatelessWidget {
  const CalendarSearchActiveFiltersBar({
    required this.filters,
    required this.onClearFilters,
    required this.onRemoveChoir,
    required this.onRemoveVoice,
    required this.onRemoveClass,
    required this.onRemoveSchoolTrack,
    required this.onRemoveDiet,
    super.key,
  });

  final CalendarFiltersState filters;
  final VoidCallback onClearFilters;
  final ValueChanged<String> onRemoveChoir;
  final ValueChanged<String> onRemoveVoice;
  final ValueChanged<String> onRemoveClass;
  final ValueChanged<String> onRemoveSchoolTrack;
  final ValueChanged<String> onRemoveDiet;

  @override
  Widget build(BuildContext context) {
    if (!filters.hasVisibleDeviationChips) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[
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
    ];

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
            onDeleted: () => _handleChipInteraction(
              () => onRemoveSchoolTrack(schoolTrack),
            ),
          ),
        ),
      );
    }
    for (final diet in filters.dietDeviations) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InputChip(
            label: Text('Ernährung: ${_formatDietFilterChipValue(diet)}'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onDeleted: () => _handleChipInteraction(() => onRemoveDiet(diet)),
          ),
        ),
      );
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

String _formatDietFilterChipValue(String value) {
  final diet = BackendDietCodec.fromBackend(value);
  if (diet != BackendDiet.unknown) {
    return diet.displayLabel;
  }
  return _formatFilterChipValue(value);
}
