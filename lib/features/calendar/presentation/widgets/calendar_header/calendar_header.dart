import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:chronoapp/features/calendar/presentation/providers/calendar_providers.dart';
import 'calendar_handle.dart';
import 'custom_table_calendar.dart';

class CalendarHeader extends ConsumerStatefulWidget {
  const CalendarHeader({super.key});

  @override
  ConsumerState<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends ConsumerState<CalendarHeader> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  double _dragDelta = 0;
  bool _isHandlePressed = false;

  static const List<CalendarFormat> _formats = <CalendarFormat>[
    CalendarFormat.week,
    CalendarFormat.twoWeeks,
    CalendarFormat.month,
  ];

  void _changeFormatByDrag({required bool dragDown}) {
    final currentIndex = _formats.indexOf(_calendarFormat);
    if (currentIndex == -1) return;

    final nextIndex = dragDown
        ? (currentIndex + 1).clamp(0, _formats.length - 1)
        : (currentIndex - 1).clamp(0, _formats.length - 1);

    if (nextIndex != currentIndex) {
      setState(() {
        _calendarFormat = _formats[nextIndex];
      });
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

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragDelta = 0;
    setState(() {
      _isHandlePressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final selectedDay = ref.watch(selectedDayProvider);
    String monthName = DateFormat.MMMM('de').format(selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          AppBar(
            title: Text(monthName),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
            ],
          ),
          CustomTableCalendar(
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
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
            onVerticalDragStart: (_) {
              setState(() {
                _isHandlePressed = true;
              });
            },
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
          ),
        ],
      ),
    );
  }
}
