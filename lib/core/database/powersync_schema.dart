import 'package:powersync/powersync.dart';

/// Muss exakt zum **Postgres-Tabellennamen** passen, den PowerSync sync’t
/// (z. B. `SELECT * FROM calendar_events` → lokale Tabelle `calendar_events`).
const String kCalendarEventsTable = 'calendar_events';
const String kCalendarSeriesTable = 'calendar_series';
const String kProfilesTable = 'profiles';
const String kKlassenTable = 'klassen';
const String kSubjectsTable = 'subjects';
const String kEventSchedulesTable = 'event_schedules';
const String kGuardianChildLinksTable = 'guardian_child_links';
const String kHomeworkSyntaxSuggestionsTable = 'homework_syntax_suggestions';
const String kHomeworkContributionsTable = 'homework_contributions';
const String kHomeworkTasksTable = 'homework_tasks';
const String kHomeworkPeerDismissalsTable = 'homework_peer_dismissals';
const String kSchoolAssessmentsTable = 'school_assessments';

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
      Column.text('diet'),
      Column.text('image_paths'),
      Column.text('series_id'),
      Column.text('recurrence_id'),
    ],
    indexes: [
      Index('calendar_events_start_time', [IndexedColumn('start_time')]),
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
      Column.text('schooltrack'),
      Column.text('class'),
      Column.text('diet'),
      Column.text('series_start'),
      Column.text('series_end'),
      Column.text('subject_id'),
    ],
    indexes: [
      Index('calendar_series_series_start', [IndexedColumn('series_start')]),
      Index('calendar_series_subject_id', [IndexedColumn('subject_id')]),
    ],
  ),
  Table(
    kProfilesTable,
    [
      Column.text('first_name'),
      Column.text('last_name'),
      Column.text('class_name'),
      Column.text('schooltrack'),
      Column.text('voice'),
      Column.text('role'),
      Column.text('choir'),
      Column.text('diet'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('onboarding_completed_at'),
      Column.text('calendar_preferences'),
      Column.text('fcm_token'),
      Column.text('fcm_token_updated_at'),
      Column.text('active_child_id'),
    ],
    indexes: [
      Index('profiles_class_name', [IndexedColumn('class_name')]),
      Index('profiles_updated_at', [IndexedColumn('updated_at')]),
    ],
  ),
  Table(
    kGuardianChildLinksTable,
    [
      Column.text('guardian_id'),
      Column.text('child_id'),
      Column.text('status'),
      Column.text('created_at'),
      Column.text('responded_at'),
      Column.text('reminder_sent_at'),
      Column.text('child_share_permissions'),
    ],
    indexes: [
      Index(
        'guardian_child_links_guardian_id',
        [IndexedColumn('guardian_id')],
      ),
      Index(
        'guardian_child_links_child_id',
        [IndexedColumn('child_id')],
      ),
    ],
  ),
  Table(
    kKlassenTable,
    [Column.text('class_name')],
    indexes: [
      Index('klassen_class_name', [IndexedColumn('class_name')]),
    ],
  ),
  Table(
    kSubjectsTable,
    [
      Column.text('name'),
      Column.text('default_color'),
    ],
    indexes: [
      Index('subjects_name', [IndexedColumn('name')]),
    ],
  ),
  Table(
    kEventSchedulesTable,
    [
      Column.text('event_id'),
      Column.text('title'),
      Column.text('description'),
      Column.text('start_time'),
      Column.text('end_time'),
      Column.text('location'),
      Column.text('choir'),
      Column.text('voices'),
      Column.text('created_at'),
    ],
    indexes: [
      Index('event_schedules_event_id', [IndexedColumn('event_id')]),
    ],
  ),
  Table(
    kHomeworkSyntaxSuggestionsTable,
    [
      Column.text('category'),
      Column.text('label'),
      Column.text('shorthand'),
      Column.text('aliases'),
      Column.text('insert_template'),
      Column.text('chip_color_key'),
      Column.integer('sort_order'),
      Column.integer('is_global'),
      Column.text('created_by'),
      Column.text('created_at'),
    ],
    indexes: [
      Index(
        'homework_syntax_suggestions_category',
        [IndexedColumn('category')],
      ),
    ],
  ),
  Table(
    kHomeworkContributionsTable,
    [
      Column.text('profile_id'),
      Column.text('class_name'),
      Column.text('schooltrack'),
      Column.text('subject_id'),
      Column.text('lesson_date'),
      Column.text('fragments'),
      Column.text('fragment_hashes'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index(
        'homework_contributions_class_day',
        [IndexedColumn('class_name'), IndexedColumn('lesson_date')],
      ),
      Index(
        'homework_contributions_profile',
        [IndexedColumn('profile_id')],
      ),
    ],
  ),
  Table(
    kHomeworkTasksTable,
    [
      Column.text('profile_id'),
      Column.text('title'),
      Column.text('fragments'),
      Column.text('plain_text'),
      Column.text('subject_id'),
      Column.integer('is_completed'),
      Column.text('completed_at'),
      Column.text('due_at'),
      Column.text('due_source'),
      Column.text('contribution_id'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index(
        'homework_tasks_profile',
        [IndexedColumn('profile_id')],
      ),
    ],
  ),
  Table(
    kHomeworkPeerDismissalsTable,
    [
      Column.text('profile_id'),
      Column.text('canonical_key'),
      Column.text('subject_id'),
      Column.text('lesson_date'),
      Column.text('created_at'),
    ],
    indexes: [
      Index(
        'homework_peer_dismissals_profile',
        [IndexedColumn('profile_id')],
      ),
    ],
  ),
  Table(
    kSchoolAssessmentsTable,
    [
      Column.text('profile_id'),
      Column.text('kind'),
      Column.text('subject_id'),
      Column.text('scheduled_at'),
      Column.text('schedule_source'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index(
        'school_assessments_profile',
        [IndexedColumn('profile_id')],
      ),
      Index(
        'school_assessments_subject_scheduled',
        [IndexedColumn('subject_id'), IndexedColumn('scheduled_at')],
      ),
    ],
  ),
]);
