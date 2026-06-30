-- Reduziert Supabase-Last: seltenerer Cron + Trigger nur bei relevanten Änderungen.

CREATE OR REPLACE FUNCTION public.trigger_schedule_live_activity_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_event_id uuid;
  cron_secret text;
  request_body jsonb;
BEGIN
  IF TG_TABLE_NAME = 'calendar_events' THEN
    IF TG_OP = 'UPDATE' THEN
      IF (OLD.event_name, OLD.start_time, OLD.end_time, OLD.location, OLD.type,
          OLD.choir, OLD.voices, OLD.schooltrack, OLD.class, OLD.series_id,
          OLD.recurrence_id)
         IS NOT DISTINCT FROM
         (NEW.event_name, NEW.start_time, NEW.end_time, NEW.location, NEW.type,
          NEW.choir, NEW.voices, NEW.schooltrack, NEW.class, NEW.series_id,
          NEW.recurrence_id) THEN
        RETURN NEW;
      END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
      target_event_id := OLD.id;
      request_body := jsonb_build_object(
        'mode', 'change',
        'event_id', target_event_id,
        'op', TG_OP,
        'source', 'calendar_events',
        'event_snapshot', jsonb_build_object(
          'id', OLD.id,
          'event_name', OLD.event_name,
          'choir', OLD.choir,
          'voices', OLD.voices,
          'type', OLD.type
        )
      );
    ELSE
      target_event_id := NEW.id;
      request_body := jsonb_build_object(
        'mode', 'change',
        'event_id', target_event_id,
        'op', TG_OP,
        'source', 'calendar_events'
      );
    END IF;
  ELSIF TG_TABLE_NAME = 'event_schedules' THEN
    IF TG_OP = 'UPDATE' THEN
      IF (OLD.event_id, OLD.title, OLD.description, OLD.start_time, OLD.end_time,
          OLD.location, OLD.choir, OLD.voices)
         IS NOT DISTINCT FROM
         (NEW.event_id, NEW.title, NEW.description, NEW.start_time, NEW.end_time,
          NEW.location, NEW.choir, NEW.voices) THEN
        RETURN NEW;
      END IF;
    END IF;

    IF TG_OP = 'DELETE' THEN
      target_event_id := OLD.event_id;
    ELSE
      target_event_id := NEW.event_id;
    END IF;
    request_body := jsonb_build_object(
      'mode', 'change',
      'event_id', target_event_id,
      'op', TG_OP,
      'source', 'event_schedules'
    );
  ELSE
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
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/schedule-live-activity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', cron_secret
    ),
    body := request_body
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.trigger_schedule_live_activity_change() IS
  'Ruft schedule-live-activity bei relevanten Termin-/Ablaufplan-Änderungen auf (ohne reine Metadaten-Updates).';

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
  '*/5 * * * *',
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
