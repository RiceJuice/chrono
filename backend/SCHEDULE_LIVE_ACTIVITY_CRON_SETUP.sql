-- Einmalig im Supabase SQL Editor ausführen (ersetzt ALTER DATABASE SET).
-- Secret muss identisch zu: supabase secrets set SCHEDULE_LIVE_ACTIVITY_CRON_SECRET=...

-- 1) Secret im Vault ablegen (Wert anpassen!)
SELECT vault.create_secret(
  'HIER-DEIN-SECRET-EINFÜGEN',
  'schedule_live_activity_cron_secret',
  'Cron-Header für schedule-live-activity Edge Function'
);

-- 2) Cron-Job neu planen (liest Secret aus Vault)
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
