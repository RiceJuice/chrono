import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
import '../../domain/models/calendar_entry.dart';
import '../../domain/repositories/calendar_repository.dart';

part 'calendar_providers.g.dart';


@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  DateTime build() {

    final now = DateTime.now().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDate) {

    final localDay = newDate.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

@riverpod
class FocusedDay extends _$FocusedDay {
  @override
  DateTime build() {
    final now = DateTime.now().toLocal();

    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime newDay) {
    final localDay = newDay.toLocal();
    state = DateTime(localDay.year, localDay.month, localDay.day);
  }
}

@riverpod
CalendarRepository calendarRepository(Ref ref) { 
  return CalendarRepository();
}

@riverpod
Future<List<CalendarEntry>> calendarEntries(Ref ref) async {
  final selectedDay = ref.watch(selectedDayProvider);
  final repository = ref.watch(calendarRepositoryProvider);
  
  return repository.getEntriesForDay(selectedDay);
}
final calendarEntriesForDayProvider =
    FutureProvider.autoDispose.family<List<CalendarEntry>, DateTime>((ref, day) async {
  final repository = ref.watch(calendarRepositoryProvider);
  return repository.getEntriesForDay(day);
});