import 'package:chronoapp/core/database/backend_enums.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/features/calendar/domain/filter/calendar_filter_text.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_header/calendar_settings_filter_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/calendar_event_form_state.dart';
import '../chips/event_enum_chip_section.dart';

class EventAudienceSection extends ConsumerWidget {
  const EventAudienceSection({
    super.key,
    required this.state,
    required this.onChanged,
    required this.classOptions,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;
  final List<String> classOptions;

  static List<String> get _choirOptions => BackendChoir.values
      .where((v) => v != BackendChoir.unknown)
      .map((v) => v.toBackend())
      .whereType<String>()
      .toList();

  static List<String> get _voiceOptions => BackendVoice.values
      .where((v) => v != BackendVoice.unknown)
      .map((v) => v.toBackend())
      .whereType<String>()
      .toList();

  static List<String> get _schoolTrackOptions => BackendSchoolTrack.values
      .where((v) => v != BackendSchoolTrack.unknown)
      .map((v) => v.toBackend())
      .whereType<String>()
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final chipBg = scheme.surfaceContainerHighest;
    final selectedColor = scheme.primary;

    final choirSelected = state.choir.toBackend();
    final voiceSelected = state.voices
        .map((v) => v.toBackend())
        .whereType<String>()
        .toList();
    final schoolSelected = state.schoolTrack.toBackend();
    final classSelected = normalizeCalendarFilterText(state.className);

    final classes = <String>{
      ...classOptions,
      ?classSelected,
    }.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventSingleSelectChipSection(
          title: 'Chor',
          options: _choirOptions,
          labelFor: calendarFilterChoirLabel,
          selectedValue: choirSelected,
          selectedColor: selectedColor,
          chipBackgroundColor: chipBg,
          onSelected: (value) {
            final choir = value == null
                ? BackendChoir.unknown
                : BackendChoirCodec.fromBackend(value);
            onChanged(state.copyWith(choir: choir));
          },
        ),
        const SizedBox(height: AppSpacing.m),
        EventMultiSelectChipSection(
          title: 'Stimmen',
          options: _voiceOptions,
          labelFor: calendarFilterVoiceLabel,
          selectedValues: voiceSelected,
          selectedColor: selectedColor,
          chipBackgroundColor: chipBg,
          onToggle: (value) {
            final parsed = BackendVoiceCodec.fromBackend(value);
            if (parsed == BackendVoice.unknown) return;
            final next = List<BackendVoice>.from(state.voices);
            if (next.contains(parsed)) {
              next.remove(parsed);
            } else {
              next.add(parsed);
            }
            onChanged(state.copyWith(voices: next));
          },
        ),
        const SizedBox(height: AppSpacing.m),
        EventSingleSelectChipSection(
          title: 'Schulzweig',
          options: _schoolTrackOptions,
          labelFor: calendarFilterSchoolTrackLabel,
          selectedValue: schoolSelected,
          selectedColor: selectedColor,
          chipBackgroundColor: chipBg,
          onSelected: (value) {
            final track = value == null
                ? BackendSchoolTrack.unknown
                : BackendSchoolTrackCodec.fromBackend(value);
            onChanged(state.copyWith(schoolTrack: track));
          },
        ),
        const SizedBox(height: AppSpacing.m),
        EventSingleSelectChipSection(
          title: 'Klasse',
          options: classes,
          labelFor: calendarFilterClassLabel,
          selectedValue: classSelected,
          selectedColor: selectedColor,
          chipBackgroundColor: chipBg,
          onSelected: (value) {
            onChanged(
              state.copyWith(
                className: value,
                clearClassName: value == null,
              ),
            );
          },
        ),
      ],
    );
  }
}
