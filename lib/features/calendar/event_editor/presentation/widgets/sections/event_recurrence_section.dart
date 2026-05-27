import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/core/widgets/app_hairline_divider.dart';
import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

import '../../../domain/calendar_event_form_state.dart';
import '../event_form_island.dart';
import '../event_form_island_row.dart';
import '../pickers/event_date_time_pickers.dart';
import '../pickers/event_inline_date_picker.dart';
import '../pickers/event_picker_pill.dart';

enum _RecurrenceField { weekdays, seriesStart, seriesEnd }

class EventRecurrenceSection extends StatefulWidget {
  const EventRecurrenceSection({
    super.key,
    required this.state,
    required this.onChanged,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;

  @override
  State<EventRecurrenceSection> createState() => _EventRecurrenceSectionState();
}

class _EventRecurrenceSectionState extends State<EventRecurrenceSection> {
  static const _expandDuration = Duration(milliseconds: 280);
  static const _expandCurve = Curves.easeInOutCubic;

  _RecurrenceField? _activeField;

  void _toggleField(_RecurrenceField field) {
    final opening = _activeField != field;
    AppHaptics.expandToggle(opening: opening);
    setState(() {
      _activeField = opening ? field : null;
    });
  }

  bool _isActive(_RecurrenceField field) => _activeField == field;

  @override
  void didUpdateWidget(covariant EventRecurrenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final freq = widget.state.seriesEdit?.frequency;
    if (freq != Frequency.weekly && _activeField == _RecurrenceField.weekdays) {
      setState(() => _activeField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.state.seriesEdit;
    if (series == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant.withValues(alpha: 0.22);

    return EventFormIsland(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FrequencyRow(
              frequency: series.frequency,
              onChanged: (freq) {
                widget.onChanged(
                  widget.state.copyWith(
                    seriesEdit: series.copyWith(frequency: freq),
                  ),
                );
              },
            ),
            if (series.frequency == Frequency.weekly) ...[
              _islandDivider(dividerColor),
              _ExpandableRecurrenceBlock(
                row: EventFormIslandRow(
                  label: 'Wochentage',
                  trailing: EventPickerPill(
                    label: _WeekdayLabels.formatSelection(series.weekdays),
                    isActive: _isActive(_RecurrenceField.weekdays),
                    onTap: () => _toggleField(_RecurrenceField.weekdays),
                  ),
                ),
                expandedChild: _isActive(_RecurrenceField.weekdays)
                    ? _InlineWeekdayPicker(
                        weekdays: series.weekdays,
                        onChanged: (days) {
                          widget.onChanged(
                            widget.state.copyWith(
                              seriesEdit: series.copyWith(weekdays: days),
                            ),
                          );
                        },
                      )
                    : null,
              ),
            ],
            _islandDivider(dividerColor),
            _ExpandableRecurrenceBlock(
              row: EventFormIslandRow(
                label: 'Serienbeginn',
                trailing: EventPickerPill(
                  label: EventDateTimePickers.formatDate(series.seriesStart),
                  isActive: _isActive(_RecurrenceField.seriesStart),
                  onTap: () => _toggleField(_RecurrenceField.seriesStart),
                ),
              ),
              expandedChild: _isActive(_RecurrenceField.seriesStart)
                  ? _inlineDatePicker(
                      scheme,
                      value: series.seriesStart,
                      onChanged: (day) {
                        widget.onChanged(
                          widget.state.copyWith(
                            seriesEdit: series.copyWith(seriesStart: day),
                          ),
                        );
                      },
                    )
                  : null,
            ),
            _islandDivider(dividerColor),
            _ExpandableRecurrenceBlock(
              row: EventFormIslandRow(
                label: 'Serienende',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EventPickerPill(
                      label: series.seriesEnd == null
                          ? 'Kein Ende'
                          : EventDateTimePickers.formatDate(series.seriesEnd!),
                      isActive: _isActive(_RecurrenceField.seriesEnd),
                      onTap: () => _toggleField(_RecurrenceField.seriesEnd),
                    ),
                    if (series.seriesEnd != null) ...[
                      const SizedBox(width: AppSpacing.s),
                      TextButton(
                        onPressed: () {
                          AppHaptics.selection();
                          widget.onChanged(
                            widget.state.copyWith(
                              seriesEdit: series.copyWith(clearSeriesEnd: true),
                            ),
                          );
                        },
                        child: Text(
                          'Entfernen',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              expandedChild: _isActive(_RecurrenceField.seriesEnd)
                  ? _inlineDatePicker(
                      scheme,
                      value: series.seriesEnd ?? AppDateTime.todayLocal(),
                      onChanged: (day) {
                        widget.onChanged(
                          widget.state.copyWith(
                            seriesEdit: series.copyWith(seriesEnd: day),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _islandDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: AppHairlineDivider.horizontal(color: color),
    );
  }

  Widget _inlineDatePicker(
    ColorScheme scheme, {
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: EventInlineDatePicker(value: value, onChanged: onChanged),
    );
  }
}

class _ExpandableRecurrenceBlock extends StatelessWidget {
  const _ExpandableRecurrenceBlock({
    required this.row,
    required this.expandedChild,
  });

  final EventFormIslandRow row;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        AnimatedSize(
          duration: _EventRecurrenceSectionState._expandDuration,
          curve: _EventRecurrenceSectionState._expandCurve,
          alignment: Alignment.topCenter,
          child: expandedChild ?? const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({
    required this.frequency,
    required this.onChanged,
  });

  final Frequency frequency;
  final ValueChanged<Frequency> onChanged;

  static const _options = <(Frequency, String)>[
    (Frequency.daily, 'Täglich'),
    (Frequency.weekly, 'Wöchentlich'),
    (Frequency.monthly, 'Monatlich'),
  ];

  @override
  Widget build(BuildContext context) {
    return EventFormIslandRow(
      label: 'Wiederholung',
      trailing: DropdownButton<Frequency>(
        value: frequency,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final (freq, label) in _options)
            DropdownMenuItem(value: freq, child: Text(label)),
        ],
        onChanged: (value) {
          if (value == null) return;
          AppHaptics.selection();
          onChanged(value);
        },
      ),
    );
  }
}

class _WeekdayLabels {
  _WeekdayLabels._();

  static const weekdayOrder = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static const labels = <int, String>{
    DateTime.monday: 'Montag',
    DateTime.tuesday: 'Dienstag',
    DateTime.wednesday: 'Mittwoch',
    DateTime.thursday: 'Donnerstag',
    DateTime.friday: 'Freitag',
    DateTime.saturday: 'Samstag',
    DateTime.sunday: 'Sonntag',
  };

  static String formatSelection(Set<int> weekdays) {
    if (weekdays.isEmpty) return 'Auswählen';
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => labels[d]!).join(', ');
  }
}

class _InlineWeekdayPicker extends StatelessWidget {
  const _InlineWeekdayPicker({
    required this.weekdays,
    required this.onChanged,
  });

  final Set<int> weekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final day in _WeekdayLabels.weekdayOrder)
            CheckboxListTile(
              value: weekdays.contains(day),
              title: Text(_WeekdayLabels.labels[day]!),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
              ),
              onChanged: (selected) {
                final next = Set<int>.from(weekdays);
                if (selected == true) {
                  next.add(day);
                } else {
                  next.remove(day);
                }
                if (next.isNotEmpty) {
                  AppHaptics.selection();
                  onChanged(next);
                }
              },
            ),
        ],
      ),
    );
  }
}
