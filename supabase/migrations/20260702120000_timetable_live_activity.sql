-- Stundenplan-Live-Activity: Dispatch-Dedup, Trigger, Cron alle 15 Minuten

CREATE TABLE IF NOT EXISTS public.timetable_live_activity_dispatches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  day_date text NOT NULL,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  action text NOT NULL CHECK (action IN ('start', 'update', 'end')),
  sent_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (day_date, user_id, device_id, action)
);

CREATE INDEX IF NOT EXISTS timetable_live_activity_dispatches_sent_at_idx
  ON public.timetable_live_activity_dispatches (sent_at);

ALTER TABLE public.timetable_live_activity_dispatches ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.timetable_live_activity_dispatches IS
  'Dedup für serverseitige Stundenplan-Live-Activity FCM (nur service_role).';

CREATE OR REPLACE FUNCTION public.trigger_timetable_live_activity_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cron_secret text;
  row_type text;
BEGIN
  IF TG_TABLE_NAME = 'calendar_events' THEN
    row_type := COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN OLD.type ELSE NEW.type END,
      ''
    );
  ELSIF TG_TABLE_NAME = 'calendar_series' THEN
    row_type := COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN OLD.type ELSE NEW.type END,
      ''
    );
  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF row_type NOT IN ('lesson', 'meal') THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT decrypted_secret INTO cron_secret
  FROM vault.decrypted_secrets
  WHERE name = 'schedule_live_activity_cron_secret'
  LIMIT 1;

  IF cron_secret IS NULL OR cron_secret = '' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  PERFORM net.http_post(
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/timetable-live-activity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', cron_secret
    ),
    body := jsonb_build_object(
      'mode', 'change',
      'op', TG_OP,
      'source', TG_TABLE_NAME
    )
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.trigger_timetable_live_activity_change() IS
  'Ruft timetable-live-activity bei Stunden-/Essens-Änderungen auf.';

DROP TRIGGER IF EXISTS timetable_live_activity_calendar_events_change
  ON public.calendar_events;
CREATE TRIGGER timetable_live_activity_calendar_events_change
  AFTER INSERT OR UPDATE OR DELETE ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_timetable_live_activity_change();

DROP TRIGGER IF EXISTS timetable_live_activity_calendar_series_change
  ON public.calendar_series;
CREATE TRIGGER timetable_live_activity_calendar_series_change
  AFTER INSERT OR UPDATE OR DELETE ON public.calendar_series
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_timetable_live_activity_change();

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'timetable-live-activity') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'timetable-live-activity';
  END IF;
END $$;

SELECT cron.schedule(
  'timetable-live-activity',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/timetable-live-activity',
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
