-- Einmalig im Supabase SQL Editor ausführen (ersetzt ALTER DATABASE SET).
-- Secret muss identisch zu: supabase secrets set SCHEDULE_LIVE_ACTIVITY_CRON_SECRET=...

-- 1) Secret im Vault ablegen (Wert anpassen!)
SELECT vault.create_secret(
  'HIER-DEIN-SECRET-EINFÜGEN',
  'schedule_live_activity_cron_secret',
  'Interner Header für live-activity Edge Function'
);

-- 2) Nach Migration 20260706140000: Jobs in live_activity_jobs (Event + Stundenplan).
--    Fehlendes Secret → Einträge in live_activity_job_errors + WARNING im Postgres-Log.
DO $$
DECLARE
  r record;
  d date;
BEGIN
  FOR r IN
    SELECT id
    FROM public.calendar_events
    WHERE lower(trim(coalesce(type, ''))) = 'event'
      AND end_time > now()
  LOOP
    PERFORM public.sync_event_live_activity_jobs(r.id);
  END LOOP;

  PERFORM public.sync_timetable_jobs_horizon();
END $$;

-- 3) Diagnose: geplante Jobs prüfen
-- SELECT kind, reference_id, user_id, action, run_at FROM live_activity_jobs ORDER BY run_at LIMIT 50;

-- 4) Diagnose: Setup-Fehler
-- SELECT * FROM live_activity_job_errors ORDER BY created_at DESC LIMIT 20;
