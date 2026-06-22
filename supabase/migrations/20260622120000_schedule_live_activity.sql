-- Live Activity: Geräte-Metadaten + Dispatch-Dedup + pg_cron Trigger

ALTER TABLE public.profile_push_devices
  ADD COLUMN IF NOT EXISTS push_to_start_token text,
  ADD COLUMN IF NOT EXISTS live_activity_push_token text,
  ADD COLUMN IF NOT EXISTS schedule_filter text NOT NULL DEFAULT 'all'
    CHECK (schedule_filter IN ('all', 'mine'));

COMMENT ON COLUMN public.profile_push_devices.push_to_start_token IS
  'iOS 17.2+ Push-to-Start Token für Live Activities';
COMMENT ON COLUMN public.profile_push_devices.live_activity_push_token IS
  'Aktueller Live-Activity Push-Token (iOS)';
COMMENT ON COLUMN public.profile_push_devices.schedule_filter IS
  'Nutzerfilter für Ablaufplan-Live-Activities: all | mine';

CREATE TABLE IF NOT EXISTS public.schedule_live_activity_dispatches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  action text NOT NULL CHECK (action IN ('start', 'update', 'end')),
  sent_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (schedule_id, user_id, device_id, action)
);

CREATE INDEX IF NOT EXISTS schedule_live_activity_dispatches_sent_at_idx
  ON public.schedule_live_activity_dispatches (sent_at);

ALTER TABLE public.schedule_live_activity_dispatches ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.schedule_live_activity_dispatches IS
  'Dedup für serverseitige Live-Activity FCM-Auslösung (nur service_role).';

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;

-- Secret: gleicher Wert wie SCHEDULE_LIVE_ACTIVITY_CRON_SECRET (Edge Function).
-- Einmalig im SQL Editor (nach Migration):
--   SELECT vault.create_secret('<secret>', 'schedule_live_activity_cron_secret', 'Cron secret');
-- Bei bestehendem Secret: vault.update_secret via Dashboard oder neu anlegen.

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
