import 'package:powersync/powersync.dart';

/// Muss exakt zum **Postgres-Tabellennamen** passen, den PowerSync sync’t
/// (z. B. `SELECT * FROM calendar_events` → lokale Tabelle `calendar_events`).
const String kCalendarEventsTable = 'calendar_events';
const String kCalendarSeriesTable = 'calendar_series';
const String kProfilesTable = 'profiles';
const String kKlassenTable = 'klassen';

/// Client-Schema für [kCalendarEventsTable] — Spalten wie in Supabase/Postgres
/// und [CalendarEntry]/[CalendarEntryMapper].
///
/// - `start_time` / `end_time`: ISO-8601-Strings (SQLite TEXT).
/// - `type`: `lesson` | `meal` | `event` | `choir` (wie im Mapper).
/// - `image_paths`: Array-Payload aus Backend (wird im Data-Layer aufgelöst).
///
/// PowerSync ergänzt `id` automatisch — hier nicht deklarieren.
///
/// **Hinweis:** Schema-/Tabellenwechsel kann ein neues lokales DB-File brauchen
/// (App-Daten löschen oder DB-Pfad bumpen), sonst bleibt eine alte leere Tabelle.
const powersyncSchema = Schema([
  Table(
    kCalendarEventsTable,
    [
      Column.text('event_name'),
      Column.text('description'),
      Column.text('location'),
      Column.text('note'),
      Column.text('start_time'),
      Column.text('end_time'),
      Column.text('type'),
      Column.text('choir'),
      Column.text('voices'),
      Column.text('schooltrack'),
      Column.text('class'),
      Column.text('image_paths'),
      Column.text('series_id'),
      Column.text('recurrence_id'),
    ],
    indexes: [
      Index(
        'calendar_events_start_time',
        [IndexedColumn('start_time')],
      ),
    ],
  ),
  Table(
    kCalendarSeriesTable,
    [
      Column.text('event_name'),
      Column.text('rrule'),
      Column.text('start_time'),
      Column.text('end_time'),
      Column.text('location'),
      Column.text('type'),
      Column.text('choir'),
      Column.text('voices'),
      Column.text('class'),
      Column.text('series_start'),
      Column.text('series_end'),
    ],
    indexes: [
      Index(
        'calendar_series_series_start',
        [IndexedColumn('series_start')],
      ),
    ],
  ),
  Table(
    kProfilesTable,
    [
      Column.text('first_name'),
      Column.text('last_name'),
      Column.text('class_name'),
      Column.text('voice'),
      Column.text('role'),
      Column.text('choir'),
      Column.text('diet'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index(
        'profiles_class_name',
        [IndexedColumn('class_name')],
      ),
      Index(
        'profiles_updated_at',
        [IndexedColumn('updated_at')],
      ),
    ],
  ),
  Table(
    kKlassenTable,
    [
      Column.text('class_name'),
    ],
    indexes: [
      Index(
        'klassen_class_name',
        [IndexedColumn('class_name')],
      ),
    ],
  ),
]);
