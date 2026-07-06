-- Einmalig im Supabase SQL Editor ausführen (ersetzt ALTER DATABASE SET).
-- Secret muss identisch zu: supabase secrets set SCHEDULE_LIVE_ACTIVITY_CRON_SECRET=...

-- 1) Secret im Vault ablegen (Wert anpassen!)
SELECT vault.create_secret(
  'HIER-DEIN-SECRET-EINFÜGEN',
  'schedule_live_activity_cron_secret',
  'Interner Header für schedule-live-activity Edge Function'
);

-- 2) Minütlicher Polling-Cron ist entfernt — Dispatch wird bedarfsgesteuert
--    über event_live_activity_jobs (Migration 20260704130000) geplant.
--    Nach dem Secret-Setup bestehende Events nachplanen:
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id
    FROM public.calendar_events
    WHERE lower(trim(coalesce(type, ''))) = 'event'
      AND end_time > now()
  LOOP
    PERFORM public.sync_event_live_activity_jobs(r.id);
  END LOOP;
END $$;
