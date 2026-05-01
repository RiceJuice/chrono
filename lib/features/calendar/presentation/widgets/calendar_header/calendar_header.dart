import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_view_options.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'calendar_handle.dart';
import 'custom_table_calendar.dart';

class CalendarHeader extends ConsumerStatefulWidget {
  const CalendarHeader({
    required this.onSearchPressed,
    required this.onFilterPressed,
    required this.viewOptions,
    this.viewMode = CalendarViewMode.day,
    this.onViewModeChanged,
    this.onViewMenuPressed,
    this.showCenteredViewControl = true,
    this.weekTimetableMode = false,
    super.key,
  });

  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final List<CalendarViewOption> viewOptions;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode>? onViewModeChanged;
  final VoidCallback? onViewMenuPressed;
  final bool showCenteredViewControl;
  final bool weekTimetableMode;

  @override
  ConsumerState<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends ConsumerState<CalendarHeader> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  double _dragDelta = 0;
  bool _isHandlePressed = false;

  static const List<CalendarFormat> _formats = <CalendarFormat>[
    CalendarFormat.week,
    CalendarFormat.twoWeeks,
    CalendarFormat.month,
  ];

  void _changeFormatByDrag({required bool dragDown}) {
    if (widget.weekTimetableMode) return;
    final currentIndex = _formats.indexOf(_calendarFormat);
    if (currentIndex == -1) return;

    final nextIndex = dragDown
        ? (currentIndex + 1).clamp(0, _formats.length - 1)
        : (currentIndex - 1).clamp(0, _formats.length - 1);

    if (nextIndex != currentIndex) {
      setState(() {
        _calendarFormat = _formats[nextIndex];
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDelta += details.delta.dy;
    const threshold = 30.0;

    if (_dragDelta >= threshold) {
      _changeFormatByDrag(dragDown: true);
      _dragDelta = 0;
    } else if (_dragDelta <= -threshold) {
      _changeFormatByDrag(dragDown: false);
      _dragDelta = 0;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isHandlePressed = true;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragDelta = 0;
    setState(() {
      _isHandlePressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleDay = widget.weekTimetableMode
        ? ref.watch(focusedDayProvider)
        : ref.watch(selectedDayProvider);
    final monthName = DateFormat.MMMM('de').format(titleDay);
    final weekNumber = _isoWeekNumber(titleDay);
    final calendarFormat = widget.weekTimetableMode
        ? CalendarFormat.week
        : _calendarFormat;
    final selectedViewOption = calendarViewOptionFor(widget.viewMode);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                monthName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              flexibleSpace: widget.showCenteredViewControl
                  ? SafeArea(
                      bottom: false,
                      child: Center(
                        child: _CalendarViewSegmentedControl(
                          value: widget.viewMode,
                          options: widget.viewOptions,
                          onChanged: (value) {
                            if (value == widget.viewMode) return;
                            HapticFeedback.selectionClick();
                            widget.onViewModeChanged?.call(value);
                          },
                        ),
                      ),
                    )
                  : null,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              actions: [
                if (!widget.showCenteredViewControl &&
                    widget.onViewMenuPressed != null)
                  _CalendarViewMenuButton(
                    option: selectedViewOption,
                    onPressed: widget.onViewMenuPressed!,
                  ),
                IconButton(
                  onPressed: widget.onFilterPressed,
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
                IconButton(
                  onPressed: widget.onSearchPressed,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                CustomTableCalendar(
                  calendarFormat: calendarFormat,
                  weekTimetableMode: widget.weekTimetableMode,
                  leftGutterWidth: widget.weekTimetableMode
                      ? kCalendarTimelineGutterWidth
                      : 0,
                  onFormatChanged: (format) {
                    if (widget.weekTimetableMode) return;
                    if (_calendarFormat == format) return;
                    setState(() {
                      _calendarFormat = format;
                    });
                    HapticFeedback.mediumImpact();
                  },
                ),
                if (widget.weekTimetableMode)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: kCalendarTimelineGutterWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'KW',
                                style: TextStyle(color: Color(0xFF4F4F4F)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$weekNumber',
                                style: DefaultTextStyle.of(context).style,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (!widget.weekTimetableMode)
              CalendarHandle(
                isPressed: _isHandlePressed,
                onTapDown: (_) {
                  setState(() {
                    _isHandlePressed = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isHandlePressed = false;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isHandlePressed = false;
                  });
                },
              )
            else
              SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  int _isoWeekNumber(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final weekOneThursday = firstThursday.add(
      Duration(days: DateTime.thursday - firstThursday.weekday),
    );

    return 1 + thursday.difference(weekOneThursday).inDays ~/ 7;
  }
}

class _CalendarViewSegmentedControl extends StatelessWidget {
  const _CalendarViewSegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final CalendarViewMode value;
  final List<CalendarViewOption> options;
  final ValueChanged<CalendarViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final controlWidth = (options.length * 92.0).clamp(184.0, 320.0).toDouble();

    return SizedBox(
      width: controlWidth,
      child: CupertinoSlidingSegmentedControl<CalendarViewMode>(
        groupValue: value,
        padding: const EdgeInsets.all(3),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        thumbColor: scheme.surface,
        onValueChanged: (nextValue) {
          if (nextValue == null) return;
          onChanged(nextValue);
        },
        children: {
          for (final option in options)
            option.mode: _CalendarViewSegment(
              label: option.label,
              style: textStyle,
            ),
        },
      ),
    );
  }
}

class _CalendarViewMenuButton extends StatelessWidget {
  const _CalendarViewMenuButton({
    required this.option,
    required this.onPressed,
  });

  final CalendarViewOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Ansicht: ${option.label}',
      icon: Icon(option.icon),
    );
  }
}

class _CalendarViewSegment extends StatelessWidget {
  const _CalendarViewSegment({required this.label, required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}
