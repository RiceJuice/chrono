import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:flutter/material.dart';

class BaseBottomModal extends StatelessWidget {
  final CalendarEntry entry;
  final Widget? extraContent;
  final double minHeight;

  const BaseBottomModal({
    super.key,
    required this.entry,
    this.extraContent,
    this.minHeight = 600,
  });

  String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text(entry.title, style: Theme.of(context).textTheme.titleLarge),
              if ((entry.subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(entry.subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 4),
              Text(
                '${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)} Uhr',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if ((entry.location ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Ort: ${entry.location!}', style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (extraContent != null) ...[
                const SizedBox(height: 30),
                extraContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
