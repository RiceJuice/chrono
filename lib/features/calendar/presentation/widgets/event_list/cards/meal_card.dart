import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/text_content.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/cards/widgets/time_column.dart';
import 'package:chronoapp/features/calendar/presentation/widgets/event_list/modals/base_bottom_modal.dart';
import 'package:flutter/material.dart';
import 'package:chronoapp/core/theme/theme_tokens.dart';
import '../../../../domain/models/calendar_entry.dart';

class MealCard extends StatelessWidget {
  final CalendarEntry entry;
  const MealCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => BaseBottomModal(entry: entry),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      leading: TimeColumn(entry: entry),
      title: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.s),
          color: scheme.surface,
        ),
        // IntrinsicHeight sorgt dafür, dass die Row so hoch ist wie ihr höchstes Kind
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // WICHTIG: Streckt Kinder auf die volle Höhe
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 20, 0, 20),
                  child: TextContent(entry: entry),
                ),
              ),
              if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppRadius.s),
                  bottomRight: Radius.circular(AppRadius.s),
                ),
                child: Image.network(
                  entry.imageUrls![0],
                  width: 120,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
