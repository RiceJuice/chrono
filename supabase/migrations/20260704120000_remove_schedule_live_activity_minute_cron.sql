-- Entfernt den minütlichen Polling-Cron für schedule-live-activity.
-- Dispatch-Zeitpunkte werden ab 20260704130000 bedarfsgesteuert geplant.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'schedule-live-activity') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'schedule-live-activity';
  END IF;
END $$;

COMMENT ON EXTENSION pg_cron IS
  'schedule-live-activity: kein globaler Minuten-Job mehr (bedarfsgesteuert via event_live_activity_jobs).';
