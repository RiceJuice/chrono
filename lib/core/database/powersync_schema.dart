import 'package:powersync/powersync.dart';

/// Muss exakt zum **Postgres-Tabellennamen** passen, den PowerSync sync’t
/// (z. B. `SELECT * FROM calendar_events` → lokale Tabelle `calendar_events`).
const String kCalendarEventsTable = 'calendar_events';

/// Client-Schema für [kCalendarEventsTable] — Spalten wie in Supabase/Postgres
/// und [CalendarEntry]/[CalendarEntryMapper].
///
/// - `start_time` / `end_time`: ISO-8601-Strings (SQLite TEXT).
/// - `type`: `lesson` | `meal` | `event` | `chor` (wie im Mapper).
/// - `accent_color`: `Color.value` als int (Flutter).
/// - `image_urls` / `tags`: JSON-Array als Text.
///
/// PowerSync ergänzt `id` automatisch — hier nicht deklarieren.
///
/// **Hinweis:** Schema-/Tabellenwechsel kann ein neues lokales DB-File brauchen
/// (App-Daten löschen oder DB-Pfad bumpen), sonst bleibt eine alte leere Tabelle.
const powersyncSchema = Schema([
  Table(
    kCalendarEventsTable,
    [
      Column.text('title'),
      Column.text('subtitle'),
      Column.text('location'),
      Column.text('start_time'),
      Column.text('end_time'),
      Column.text('type'),
      Column.integer('accent_color'),
      Column.text('image_urls'),
      Column.text('tags'),
      Column.text('user_id'),
    ],
    indexes: [
      Index(
        'calendar_events_start_time',
        [IndexedColumn('start_time')],
      ),
    ],
  ),
]);
