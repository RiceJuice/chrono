import 'dart:math' as math;

import 'package:chronoapp/core/widgets/app_apply_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<int?> showMusicLessonTimePicker(BuildContext context, int initial) {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    // The SwiftUI editor handles supported Apple builds. Use a Cupertino
    // wheel if the native editor channel is unavailable.
    var selection = initial;
    return showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => ColoredBox(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppApplyButton.cancel(
                    onPressed: () => Navigator.pop(context),
                  ),
                  AppApplyButton(
                    onPressed: () => Navigator.pop(context, selection),
                  ),
                ],
              ),
              SizedBox(
                height: 216,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    initial ~/ 60,
                    initial % 60,
                  ),
                  onDateTimeChanged: (date) =>
                      selection = date.hour * 60 + date.minute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  return showDialog<int>(
    context: context,
    builder: (context) => _ClockDialog(initial: initial),
  );
}

class _ClockDialog extends StatefulWidget {
  const _ClockDialog({required this.initial});

  final int initial;

  @override
  State<_ClockDialog> createState() => _ClockDialogState();
}

class _ClockDialogState extends State<_ClockDialog> {
  late int _hour = widget.initial ~/ 60;
  late int _minute = widget.initial % 60;
  bool _choosingMinute = false;

  void _selectMinuteAt(Offset point, double diameter) {
    final delta = point - Offset(diameter / 2, diameter / 2);
    if (delta.distance < 18) return;
    final angle = math.atan2(delta.dx, -delta.dy);
    setState(() => _minute = (angle * 30 / math.pi).round() % 60);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final availableWidth = media.size.width - media.padding.horizontal - 96;
    final diameter = availableWidth.clamp(0.0, 272.0);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24),
      scrollable: true,
      title: Text(_choosingMinute ? 'Minute wählen' : 'Stunde wählen'),
      content: SizedBox(
        width: diameter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_choosingMinute)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Eine Minute zurück',
                    onPressed: () =>
                        setState(() => _minute = (_minute - 1) % 60),
                    icon: const Icon(Icons.remove),
                  ),
                  Semantics(
                    liveRegion: true,
                    label: '$_minute Minuten',
                    excludeSemantics: true,
                    child: Text(
                      _twoDigits(_minute),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eine Minute vor',
                    onPressed: () =>
                        setState(() => _minute = (_minute + 1) % 60),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            SizedBox.square(
              dimension: diameter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: _choosingMinute
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) =>
                            _selectMinuteAt(details.localPosition, diameter),
                        onPanUpdate: (details) =>
                            _selectMinuteAt(details.localPosition, diameter),
                        child: _buildMinutes(diameter),
                      )
                    : _buildHours(diameter),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppApplyButton.cancel(onPressed: () => Navigator.pop(context)),
        if (_choosingMinute)
          TextButton(
            onPressed: () => setState(() => _choosingMinute = false),
            child: const Text('Stunde ändern'),
          ),
        if (_choosingMinute)
          AppApplyButton(
            filled: false,
            onPressed: () => Navigator.pop(context, _hour * 60 + _minute),
          )
        else
          TextButton(
            onPressed: () => setState(() => _choosingMinute = true),
            child: const Text('Weiter'),
          ),
      ],
    );
  }

  Widget _buildHours(double diameter) => Stack(
    children: [
      for (var hour = 0; hour < 24; hour++)
        _dialLabel(
          value: hour,
          position: hour % 12,
          divisions: 12,
          diameter: diameter,
          inner: hour == 0 || hour > 12,
          selected: hour == _hour,
          onTap: () => setState(() {
            _hour = hour;
            _choosingMinute = true;
          }),
          unit: 'Uhr',
        ),
    ],
  );

  Widget _buildMinutes(double diameter) => Stack(
    children: [
      if (_minute % 5 != 0)
        _dialLabel(
          value: _minute,
          position: _minute,
          divisions: 60,
          diameter: diameter,
          inner: true,
          selected: true,
        ),
      for (var minute = 0; minute < 60; minute += 5)
        _dialLabel(
          value: minute,
          position: minute,
          divisions: 60,
          diameter: diameter,
          selected: minute == _minute,
          onTap: () => setState(() => _minute = minute),
          unit: 'Minuten',
        ),
    ],
  );

  Widget _dialLabel({
    required int value,
    required int position,
    required int divisions,
    required double diameter,
    required bool selected,
    bool inner = false,
    VoidCallback? onTap,
    String? unit,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final angle = position * 2 * math.pi / divisions;
    final radius = diameter * (inner ? 0.27 : 0.41);
    final size = math.min(44.0, diameter * 0.135);
    return Positioned(
      left: (diameter - size) / 2 + radius * math.sin(angle),
      top: (diameter - size) / 2 - radius * math.cos(angle),
      width: size,
      height: size,
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: unit == null ? null : '$value $unit',
        excludeSemantics: unit != null,
        onTap: onTap,
        child: Material(
          shape: const CircleBorder(),
          color: selected ? scheme.primary : Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                _twoDigits(value),
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _twoDigits(int number) => number.toString().padLeft(2, '0');
}
