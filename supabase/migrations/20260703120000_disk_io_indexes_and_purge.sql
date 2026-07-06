-- Disk-IO-Optimierung: Indizes für Cron-/Sync-Queries + Dispatch-Bereinigung.

CREATE INDEX IF NOT EXISTS event_schedules_start_time_idx
  ON public.event_schedules (start_time);

CREATE INDEX IF NOT EXISTS event_schedules_end_time_idx
  ON public.event_schedules (end_time)
  WHERE end_time IS NOT NULL;

CREATE INDEX IF NOT EXISTS event_schedules_event_id_start_time_idx
  ON public.event_schedules (event_id, start_time);

CREATE INDEX IF NOT EXISTS calendar_events_start_time_idx
  ON public.calendar_events (start_time);

CREATE INDEX IF NOT EXISTS calendar_events_type_start_time_idx
  ON public.calendar_events (type, start_time)
  WHERE type IN ('lesson', 'meal');

CREATE INDEX IF NOT EXISTS profiles_role_idx
  ON public.profiles (role);

CREATE INDEX IF NOT EXISTS profiles_role_onboarding_idx
  ON public.profiles (role)
  WHERE onboarding_completed_at IS NOT NULL;

-- Alte Dispatch-Einträge täglich entfernen (Dedup-Tabellen wachsen sonst unbegrenzt).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'purge-live-activity-dispatches') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'purge-live-activity-dispatches';
  END IF;
END $$;

SELECT cron.schedule(
  'purge-live-activity-dispatches',
  '15 3 * * *',
  $$
  DELETE FROM public.schedule_live_activity_dispatches
  WHERE sent_at < now() - interval '14 days';
  DELETE FROM public.timetable_live_activity_dispatches
  WHERE sent_at < now() - interval '14 days';
  $$
);

COMMENT ON INDEX public.event_schedules_start_time_idx IS
  'Range-Scan für schedule-live-activity Cron (±30s Fenster).';
