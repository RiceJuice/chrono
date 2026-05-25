import 'package:chronoapp/core/haptics/app_haptics.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:flutter/material.dart';

import '../../../domain/calendar_event_form_state.dart';
import '../event_form_island.dart';
import '../event_form_island_row.dart';
import '../pickers/event_date_time_pickers.dart';
import '../pickers/event_inline_date_picker.dart';
import '../pickers/event_inline_time_picker.dart';
import '../pickers/event_picker_pill.dart';

enum _DatetimeField { start, end }

enum _PickerType { date, time }

class _ActivePicker {
  const _ActivePicker(this.field, this.type);

  final _DatetimeField field;
  final _PickerType type;

  @override
  bool operator ==(Object other) {
    return other is _ActivePicker &&
        other.field == field &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(field, type);
}

class EventDatetimeSection extends StatefulWidget {
  const EventDatetimeSection({
    super.key,
    required this.state,
    required this.onChanged,
    this.timeOnly = false,
  });

  final CalendarEventFormState state;
  final ValueChanged<CalendarEventFormState> onChanged;

  /// Bei Serienterminen: nur Uhrzeit (Datum kommt aus der Serie / Instanz).
  final bool timeOnly;

  @override
  State<EventDatetimeSection> createState() => _EventDatetimeSectionState();
}

class _EventDatetimeSectionState extends State<EventDatetimeSection> {
  static const _expandDuration = Duration(milliseconds: 280);
  static const _expandCurve = Curves.easeInOutCubic;

  _ActivePicker? _activePicker;

  void _togglePicker(_DatetimeField field, _PickerType type) {
    final next = _ActivePicker(field, type);
    final opening = _activePicker != next;
    AppHaptics.expandToggle(opening: opening);
    setState(() {
      _activePicker = opening ? next : null;
    });
  }

  bool _isActive(_DatetimeField field, _PickerType type) {
    return _activePicker == _ActivePicker(field, type);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dividerColor = scheme.outlineVariant.withValues(alpha: 0.22);

    return EventFormIsland(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ExpandableDatetimeBlock(
              label: widget.timeOnly ? 'Beginn (Uhrzeit)' : 'Beginn',
              value: widget.state.startTime,
              showDatePicker: !widget.timeOnly,
              isDateActive: _isActive(_DatetimeField.start, _PickerType.date),
              isTimeActive: _isActive(_DatetimeField.start, _PickerType.time),
              onToggleDate: () =>
                  _togglePicker(_DatetimeField.start, _PickerType.date),
              onToggleTime: () =>
                  _togglePicker(_DatetimeField.start, _PickerType.time),
              expandedPicker: _buildExpandedPicker(
                field: _DatetimeField.start,
                value: widget.state.startTime,
                showDatePicker: !widget.timeOnly,
                onDateChanged: (day) {
                  final local = widget.state.startTime.toLocal();
                  final newStart = AppDateTime.localWallTimeAsUtcInstant(
                    day,
                    hour: local.hour,
                    minute: local.minute,
                  );
                  var end = widget.state.endTime;
                  if (AppDateTime.isSameLocalDay(
                    AppDateTime.localDay(widget.state.startTime),
                    AppDateTime.localDay(widget.state.endTime),
                  )) {
                    final endLocal = widget.state.endTime.toLocal();
                    end = AppDateTime.localWallTimeAsUtcInstant(
                      day,
                      hour: endLocal.hour,
                      minute: endLocal.minute,
                    );
                  }
                  if (!end.isAfter(newStart)) {
                    end = newStart.add(const Duration(hours: 1));
                  }
                  widget.onChanged(
                    widget.state.copyWith(startTime: newStart, endTime: end),
                  );
                },
                onTimeChanged: (picked) {
                  var end = widget.state.endTime;
                  if (!end.isAfter(picked)) {
                    end = picked.add(const Duration(hours: 1));
                  }
                  widget.onChanged(
                    widget.state.copyWith(startTime: picked, endTime: end),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: dividerColor),
              ),
            ),
            _ExpandableDatetimeBlock(
              label: widget.timeOnly ? 'Ende (Uhrzeit)' : 'Ende',
              value: widget.state.endTime,
              showDatePicker: !widget.timeOnly,
              isDateActive: _isActive(_DatetimeField.end, _PickerType.date),
              isTimeActive: _isActive(_DatetimeField.end, _PickerType.time),
              onToggleDate: () =>
                  _togglePicker(_DatetimeField.end, _PickerType.date),
              onToggleTime: () =>
                  _togglePicker(_DatetimeField.end, _PickerType.time),
              expandedPicker: _buildExpandedPicker(
                field: _DatetimeField.end,
                value: widget.state.endTime,
                showDatePicker: !widget.timeOnly,
                onDateChanged: (day) {
                  final local = widget.state.endTime.toLocal();
                  var newEnd = AppDateTime.localWallTimeAsUtcInstant(
                    day,
                    hour: local.hour,
                    minute: local.minute,
                  );
                  if (!newEnd.isAfter(widget.state.startTime)) {
                    newEnd =
                        widget.state.startTime.add(const Duration(hours: 1));
                  }
                  widget.onChanged(widget.state.copyWith(endTime: newEnd));
                },
                onTimeChanged: (picked) => widget.onChanged(
                  widget.state.copyWith(endTime: picked),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _buildExpandedPicker({
    required _DatetimeField field,
    required DateTime value,
    required bool showDatePicker,
    required ValueChanged<DateTime> onDateChanged,
    required ValueChanged<DateTime> onTimeChanged,
  }) {
    final active = _activePicker;
    if (active == null || active.field != field) return null;

    final scheme = Theme.of(context).colorScheme;
    final dayAnchor = AppDateTime.localDay(value);

    Widget picker;
    if (active.type == _PickerType.date && showDatePicker) {
      picker = EventInlineDatePicker(
        value: value,
        onChanged: onDateChanged,
      );
    } else if (active.type == _PickerType.time) {
      picker = EventInlineTimePicker(
        value: value,
        dayAnchor: dayAnchor,
        onChanged: onTimeChanged,
      );
    } else {
      return null;
    }

    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: picker,
    );
  }
}

class _ExpandableDatetimeBlock extends StatelessWidget {
  const _ExpandableDatetimeBlock({
    required this.label,
    required this.value,
    required this.showDatePicker,
    required this.isDateActive,
    required this.isTimeActive,
    required this.onToggleDate,
    required this.onToggleTime,
    required this.expandedPicker,
  });

  final String label;
  final DateTime value;
  final bool showDatePicker;
  final bool isDateActive;
  final bool isTimeActive;
  final VoidCallback onToggleDate;
  final VoidCallback onToggleTime;
  final Widget? expandedPicker;

  @override
  Widget build(BuildContext context) {
    final dateLabel = EventDateTimePickers.formatDate(value);
    final timeLabel = AppDateTime.formatLocalHourMinute(value);
    final isExpanded = expandedPicker != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EventFormIslandRow(
          label: label,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDatePicker) ...[
                EventPickerPill(
                  label: dateLabel,
                  isActive: isDateActive,
                  onTap: onToggleDate,
                ),
                const SizedBox(width: AppSpacing.s),
              ],
              EventPickerPill(
                label: timeLabel,
                isActive: isTimeActive,
                onTap: onToggleTime,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: _EventDatetimeSectionState._expandDuration,
          curve: _EventDatetimeSectionState._expandCurve,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? expandedPicker!
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
