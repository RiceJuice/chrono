import 'package:intl/intl.dart';

/// Formatierung für Datum/Uhrzeit im Event-Editor.
class EventDateTimePickers {
  EventDateTimePickers._();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de');

  static String formatDate(DateTime value) => _dateFormat.format(value.toLocal());
}
