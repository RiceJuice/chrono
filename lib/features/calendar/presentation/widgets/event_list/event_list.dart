import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/calendar_providers.dart';
import 'day_page.dart';

class EventList extends ConsumerStatefulWidget {
  const EventList({super.key});

  @override
  ConsumerState<EventList> createState() => _EventListState();
}

class _EventListState extends ConsumerState<EventList> {
  late PageController _pageController;
  // Ein Referenzdatum, um Index in Datum umzurechnen (z.B. heute vor 500 Tagen)
  final DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 500),
  );

  @override
  void initState() {
    super.initState();
    // Wir berechnen den Start-Index basierend auf dem aktuellen selectedDay
    final initialDay = ref.read(selectedDayProvider);
    final initialIndex = initialDay.difference(_startDate).inDays;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final targetIndex = next.difference(_startDate).inDays;

      // Nur springen, wenn wir nicht schon auf der Seite sind
      // (verhindert Endlosschleifen beim Wischen)
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetIndex) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        // Berechne das neue Datum basierend auf dem Index
        final newDate = _startDate.add(Duration(days: index));
        // Update den Provider (Notify die App)
        ref.read(selectedDayProvider.notifier).update(newDate);
      },
      itemBuilder: (context, index) {
        final dateForPage = _startDate.add(Duration(days: index));

        // Jede Seite ist ein eigener Consumer, der SEINE Daten lädt
        return DayPage(date: dateForPage);
      },
    );
  }
}
