import '../models/calendar_entry.dart';
import '../../data/mock_data.dart';


//entweder Package oder extension selber schreiben, weil ungenaue Datumsvergleiche in der Repository-Methode

class CalendarRepository {
  List<CalendarEntry> getEntriesForDay(DateTime date) {
    // Normalize the query date to local midnight (UTC time)
    final localDate = date.toLocal();
    final queryDay = DateTime(localDate.year, localDate.month, localDate.day);

    return CalendarMockData.getEntries().where((entry) {
      // Normalize entry date the same way
      final entryLocal = entry.startTime.toLocal();
      final entryDay = DateTime(entryLocal.year, entryLocal.month, entryLocal.day);
      return entryDay == queryDay;
    }).toList();
  }
}
