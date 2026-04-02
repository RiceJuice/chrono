import 'package:chronoapp/features/calendar/domain/models/calendar_entry.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';

class BaseCalendarCard extends StatelessWidget {
  final CalendarEntry entry;
  final Color backgroundColor;
  final EdgeInsetsGeometry contentPadding;
  final Widget? leadingIndicator; // Für den farbigen Strich bei Events

  const BaseCalendarCard({
    super.key,
    required this.entry,
    required this.backgroundColor,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    this.leadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final timeStyle = Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) {
            return BaseBottomModal(entry: entry);
          },
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      leading: _buildTimeColumn(timeStyle),
      title: Container(
        padding: contentPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leadingIndicator != null) leadingIndicator!,
              Expanded(
                child: _buildTextContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hilfsmethode für die Zeit (Identisch für alle)
  Widget _buildTimeColumn(TextStyle? style) {
    String formatTime(DateTime time) =>
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(formatTime(entry.startTime), style: style),
        Text(formatTime(entry.endTime), style: style),
      ],
    );
  }

  // Hilfsmethode für Titel/Untertitel
  Widget _buildTextContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.title),
        if ((entry.subtitle ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            entry.subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}