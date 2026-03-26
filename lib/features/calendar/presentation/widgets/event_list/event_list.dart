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
  int? _currentIndex;
  // Ein Referenzdatum, um Index in Datum umzurechnen (z.B. heute vor 500 Tagen)
  late final DateTime _startDate;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today.subtract(const Duration(days: 500));

    // Wir berechnen den Start-Index basierend auf dem aktuellen selectedDay
    final initialDay = _dateOnly(ref.read(selectedDayProvider));
    final initialIndex = initialDay.difference(_startDate).inDays;
    _currentIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DateTime>(selectedDayProvider, (previous, next) {
      final targetIndex = _dateOnly(next).difference(_startDate).inDays;
      final currentIndex = _currentIndex;

      // Nur springen, wenn wir nicht schon auf der Seite sind
      // (verhindert Endlosschleifen beim Wischen)
      if (_pageController.hasClients && currentIndex != targetIndex) {
        final isLongJump =
            currentIndex != null && (targetIndex - currentIndex).abs() > 1;

        if (isLongJump) {
          // Bei großen Sprüngen direkt zum Ziel springen
          // statt jede Zwischenseite zu animieren.
          _pageController.jumpToPage(targetIndex);
        } else {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        _currentIndex = targetIndex;
      }
    });
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        _currentIndex = index;
        // Berechne das neue Datum basierend auf dem Index
        final newDate = _dateOnly(_startDate.add(Duration(days: index)));
        // Update den Provider (Notify die App)
        if (_dateOnly(ref.read(selectedDayProvider)) != newDate) {
          ref.read(selectedDayProvider.notifier).update(newDate);
        }
      },
      itemBuilder: (context, index) {
        final dateForPage = _startDate.add(Duration(days: index));

        // Jede Seite ist ein eigener Consumer, der SEINE Daten lädt
        return DayPage(date: dateForPage);
      },
    );
  }
}
