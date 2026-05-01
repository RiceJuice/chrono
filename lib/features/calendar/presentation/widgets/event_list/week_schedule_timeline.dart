import 'dart:async';

import 'package:chronoapp/core/time/app_date_time.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/calendar_week_layout_tokens.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/week_schedule_layout.dart';
import 'package:flutter/material.dart';

class WeekTimelineColumn extends StatefulWidget {
  const WeekTimelineColumn({
    required this.bounds,
    required this.totalHeight,
    this.showCurrentTime = false,
    super.key,
  });

  final WeekScheduleBounds bounds;
  final double totalHeight;
  final bool showCurrentTime;

  @override
  State<WeekTimelineColumn> createState() => _WeekTimelineColumnState();
}

class _WeekTimelineColumnState extends State<WeekTimelineColumn> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.showCurrentTime) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant WeekTimelineColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCurrentTime == widget.showCurrentTime) return;
    _timer?.cancel();
    _timer = widget.showCurrentTime
        ? Timer.periodic(const Duration(minutes: 1), (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nowMinute = widget.showCurrentTime ? _currentMinuteIfVisible() : null;
    final currentHourMinute = nowMinute == null
        ? null
        : (nowMinute ~/ 60) * 60.0;

    return SizedBox(
      width: kCalendarTimelineGutterWidth,
      height: widget.totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final label in buildTimeLabels(widget.bounds))
            if (label.minute != currentHourMinute)
              Positioned(
                top: topForMinute(label.minute, widget.bounds) + 2,
                left: 8,
                right: 2,
                child: Text(
                  label.text,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.1,
                  ),
                ),
              ),
          if (nowMinute != null)
            Positioned(
              top: topForMinute(nowMinute, widget.bounds) - 7,
              left: 8,
              right: 2,
              child: Text(
                formatMinute(nowMinute),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double? _currentMinuteIfVisible() {
    final now = AppDateTime.nowLocal();
    final nowMinute =
        now.hour * 60.0 +
        now.minute +
        now.second / 60.0 +
        now.millisecond / 60000.0;
    if (nowMinute < widget.bounds.startMinute ||
        nowMinute > widget.bounds.endMinute) {
      return null;
    }
    return nowMinute;
  }
}

class WeekHourGridPainter extends CustomPainter {
  const WeekHourGridPainter({required this.bounds, required this.lineColor});

  final WeekScheduleBounds bounds;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );

    for (final label in buildTimeLabels(bounds)) {
      final y = topForMinute(label.minute, bounds);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WeekHourGridPainter oldDelegate) {
    return oldDelegate.bounds.startMinute != bounds.startMinute ||
        oldDelegate.bounds.endMinute != bounds.endMinute ||
        oldDelegate.lineColor != lineColor;
  }
}

List<WeekTimeLabel> buildTimeLabels(WeekScheduleBounds bounds) {
  final labels = <WeekTimeLabel>[
    WeekTimeLabel(
      minute: bounds.startMinute,
      text: formatMinute(bounds.startMinute),
    ),
  ];
  final firstHour = (bounds.startMinute / 60).ceil();
  final lastHour = (bounds.endMinute / 60).floor();

  for (var hour = firstHour; hour <= lastHour; hour++) {
    final minute = hour * 60.0;
    if (minute <= bounds.startMinute || minute >= bounds.endMinute) continue;
    labels.add(WeekTimeLabel(minute: minute, text: formatMinute(minute)));
  }

  if ((bounds.endMinute - bounds.startMinute).abs() > 0.001) {
    labels.add(
      WeekTimeLabel(
        minute: bounds.endMinute,
        text: formatMinute(bounds.endMinute),
      ),
    );
  }

  return labels;
}

double topForMinute(double minute, WeekScheduleBounds bounds) {
  return (minute - bounds.startMinute) / 60.0 * kWeekScheduleHourHeight;
}

String formatMinute(double minute) {
  final wholeMinute = minute.round();
  final hour = wholeMinute ~/ 60;
  final mins = wholeMinute % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${mins.toString().padLeft(2, '0')}';
}

class WeekTimeLabel {
  const WeekTimeLabel({required this.minute, required this.text});

  final double minute;
  final String text;
}
