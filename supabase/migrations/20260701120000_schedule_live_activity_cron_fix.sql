-- Live Activity Cron: wieder jede Minute (±30s Fenster in Edge Function).
-- Der 5-Minuten-Cron hat Segmentstarts zwischen den Ticks verpasst.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'schedule-live-activity') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'schedule-live-activity';
  END IF;
END $$;

SELECT cron.schedule(
  'schedule-live-activity',
  '* * * * *',
  $$
  SELECT net.http_post(
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/schedule-live-activity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', coalesce(
        (SELECT decrypted_secret FROM vault.decrypted_secrets
         WHERE name = 'schedule_live_activity_cron_secret' LIMIT 1),
        ''
      )
    ),
    body := '{}'::jsonb
  );
  $$
);

COMMENT ON EXTENSION pg_cron IS
  'schedule-live-activity: jede Minute für zuverlässige Segment-Starts (±30s).';
