# Supabase RLS für Admin-Kalenderbearbeitung

Die App schreibt Terminänderungen lokal über PowerSync (`calendar_events`, `calendar_series`). Der Upload läuft über [`BackendConnector.uploadData`](../lib/core/database/backend_connector.dart) zu Supabase/PostgREST.

Damit Admins speichern können, braucht Postgres **Row Level Security** mit Policies für `profiles.role = 'Admin'` (exakter Wert: `Admin`, siehe [`ProfileRoleIds.admin`](../lib/core/auth/profile_role_ids.dart)).

**Wichtig:** `ALTER TABLE … DISABLE ROW LEVEL SECURITY` auf anderen Tabellen reicht nicht. Auf `calendar_events` / `calendar_series` muss RLS entweder **aus** sein oder **Schreib-Policies** haben. Ist RLS **an** ohne Policy → PostgREST-Updates treffen **0 Zeilen** (Symptom in der App: kurz gespeichert, dann weg).

Aktueller Stand (prüfen mit `pg_policies`): Migration `admin_calendar_write_policies` legt Admin-Schreibzugriff an.

## Empfohlene Policies (Beispiel)

Ersetze `auth.uid()`-Join auf `profiles` nach eurem Schema:

```sql
-- calendar_events: Admin darf lesen (falls noch nicht global) und schreiben
CREATE POLICY admin_calendar_events_write ON calendar_events
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'Admin'
    )
  );

-- calendar_series: Admin darf Serien-Master bearbeiten
CREATE POLICY admin_calendar_series_write ON calendar_series
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'Admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'Admin'
    )
  );
```

## Fehlercodes

- `42501` (insufficient privilege): RLS blockiert den Upload — Transaction wird in der App als „fatal“ abgeschlossen, Änderung geht verloren.
- Prüfen mit Supabase Logs / `get_advisors` nach Policy-Anpassung.

## Admin-Profil anlegen

Rolle **nicht** im Login-UI wählbar — nur manuell:

```sql
UPDATE profiles SET role = 'Admin' WHERE id = '<user-uuid>';
```
