-- DB-Trigger: calendar_events / event_schedules Änderungen → Live-Activity Edge Function

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
  'Ruft schedule-live-activity bei relevanten Termin-/Ablaufplan-Änderungen auf.';

DROP TRIGGER IF EXISTS schedule_live_activity_calendar_events_change
  ON public.calendar_events;
CREATE TRIGGER schedule_live_activity_calendar_events_change
  AFTER UPDATE OR DELETE ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_schedule_live_activity_change();

DROP TRIGGER IF EXISTS schedule_live_activity_event_schedules_change
  ON public.event_schedules;
CREATE TRIGGER schedule_live_activity_event_schedules_change
  AFTER INSERT OR UPDATE OR DELETE ON public.event_schedules
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_schedule_live_activity_change();
