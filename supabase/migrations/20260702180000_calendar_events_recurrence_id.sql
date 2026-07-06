-- Serien-Instanz-Overrides: stabiler Schlüssel neben series_id.

ALTER TABLE public.calendar_events
  ADD COLUMN IF NOT EXISTS recurrence_id text;

COMMENT ON COLUMN public.calendar_events.recurrence_id IS
  'ISO-8601-Instanzdatum für Serien-Overrides (series_id + recurrence_id).';
