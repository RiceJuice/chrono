-- Trigger nur bei relevanten lesson/meal-Änderungen (kein HTTP bei No-Op-UPDATEs).

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

    IF row_type NOT IN ('lesson', 'meal') THEN
      RETURN COALESCE(NEW, OLD);
    END IF;

    IF TG_OP = 'UPDATE' THEN
      IF (OLD.event_name, OLD.start_time, OLD.end_time, OLD.location, OLD.type,
          OLD.class, OLD.diet, OLD.series_id, OLD.recurrence_id)
         IS NOT DISTINCT FROM
         (NEW.event_name, NEW.start_time, NEW.end_time, NEW.location, NEW.type,
          NEW.class, NEW.diet, NEW.series_id, NEW.recurrence_id) THEN
        RETURN NEW;
      END IF;
    END IF;
  ELSIF TG_TABLE_NAME = 'calendar_series' THEN
    row_type := COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN OLD.type ELSE NEW.type END,
      ''
    );

    IF row_type NOT IN ('lesson', 'meal') THEN
      RETURN COALESCE(NEW, OLD);
    END IF;

    IF TG_OP = 'UPDATE' THEN
      IF (OLD.event_name, OLD.rrule, OLD.start_time, OLD.end_time, OLD.location,
          OLD.type, OLD.class, OLD.diet, OLD.series_start, OLD.series_end,
          OLD.subject_id)
         IS NOT DISTINCT FROM
         (NEW.event_name, NEW.rrule, NEW.start_time, NEW.end_time, NEW.location,
          NEW.type, NEW.class, NEW.diet, NEW.series_start, NEW.series_end,
          NEW.subject_id) THEN
        RETURN NEW;
      END IF;
    END IF;
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
  'Ruft timetable-live-activity nur bei relevanten Stunden-/Essens-Änderungen auf.';
