-- Bedarfsgesteuertes Scheduling für Event-Live-Activities (type = event).
-- Ersetzt den minütlichen pg_cron-Polling-Job durch Einmal-Jobs pro Start/Ende.

CREATE TABLE IF NOT EXISTS public.event_live_activity_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL,
  schedule_id uuid,
  action text NOT NULL CHECK (action IN ('start', 'end')),
  run_at timestamptz NOT NULL,
  cron_jobname text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS event_live_activity_jobs_event_schedule_action_idx
  ON public.event_live_activity_jobs (
    event_id,
    COALESCE(schedule_id, '00000000-0000-0000-0000-000000000000'::uuid),
    action
  );

CREATE INDEX IF NOT EXISTS event_live_activity_jobs_event_id_idx
  ON public.event_live_activity_jobs (event_id);

CREATE INDEX IF NOT EXISTS event_live_activity_jobs_run_at_idx
  ON public.event_live_activity_jobs (run_at);

COMMENT ON TABLE public.event_live_activity_jobs IS
  'Geplante Einmal-Dispatches für Event-Live-Activities (pg_cron → Edge Function).';

CREATE OR REPLACE FUNCTION public._timestamptz_to_cron_expr(p_at timestamptz)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT format(
    '%s %s %s %s *',
    EXTRACT(MINUTE FROM p_at AT TIME ZONE 'UTC')::int,
    EXTRACT(HOUR FROM p_at AT TIME ZONE 'UTC')::int,
    EXTRACT(DAY FROM p_at AT TIME ZONE 'UTC')::int,
    EXTRACT(MONTH FROM p_at AT TIME ZONE 'UTC')::int
  );
$$;

CREATE OR REPLACE FUNCTION public._clear_event_live_activity_jobs(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, cron
AS $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT cron_jobname
    FROM public.event_live_activity_jobs
    WHERE event_id = p_event_id
  LOOP
    BEGIN
      PERFORM cron.unschedule(r.cron_jobname);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  DELETE FROM public.event_live_activity_jobs
  WHERE event_id = p_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public._schedule_event_live_activity_job(
  p_event_id uuid,
  p_schedule_id uuid,
  p_action text,
  p_run_at timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, cron, vault
AS $$
DECLARE
  v_job_id uuid;
  v_jobname text;
  v_cron_expr text;
  v_secret text;
  v_body jsonb;
BEGIN
  IF p_run_at <= now() THEN
    RETURN;
  END IF;

  v_job_id := gen_random_uuid();
  v_jobname := 'sla-' || replace(v_job_id::text, '-', '');
  v_cron_expr := public._timestamptz_to_cron_expr(p_run_at);

  v_body := jsonb_build_object(
    'mode', 'dispatch',
    'event_id', p_event_id,
    'action', p_action,
    'job_id', v_job_id
  );
  IF p_schedule_id IS NOT NULL THEN
    v_body := v_body || jsonb_build_object('schedule_id', p_schedule_id);
  END IF;

  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets
  WHERE name = 'schedule_live_activity_cron_secret'
  LIMIT 1;

  IF v_secret IS NULL OR v_secret = '' THEN
    RETURN;
  END IF;

  INSERT INTO public.event_live_activity_jobs (
    id, event_id, schedule_id, action, run_at, cron_jobname
  ) VALUES (
    v_job_id, p_event_id, p_schedule_id, p_action, p_run_at, v_jobname
  );

  PERFORM cron.schedule(
    v_jobname,
    v_cron_expr,
    format(
      $job$
      SELECT net.http_post(
        url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/schedule-live-activity',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-cron-secret', %L
        ),
        body := %L::jsonb
      );
      SELECT cron.unschedule(%L);
      DELETE FROM public.event_live_activity_jobs WHERE id = %L::uuid;
      $job$,
      v_secret,
      v_body::text,
      v_jobname,
      v_job_id
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_event_live_activity_jobs(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event record;
  v_schedule record;
  v_schedule_count int;
  v_end_at timestamptz;
BEGIN
  PERFORM public._clear_event_live_activity_jobs(p_event_id);

  SELECT id, type, start_time, end_time
  INTO v_event
  FROM public.calendar_events
  WHERE id = p_event_id;

  IF NOT FOUND OR lower(trim(coalesce(v_event.type::text, ''))) <> 'event' THEN
    RETURN;
  END IF;

  SELECT count(*) INTO v_schedule_count
  FROM public.event_schedules
  WHERE event_id = p_event_id;

  IF v_schedule_count = 0 THEN
    PERFORM public._schedule_event_live_activity_job(
      p_event_id, NULL, 'start', v_event.start_time
    );
    PERFORM public._schedule_event_live_activity_job(
      p_event_id, NULL, 'end', v_event.end_time
    );
    RETURN;
  END IF;

  FOR v_schedule IN
    SELECT id, start_time, end_time
    FROM public.event_schedules
    WHERE event_id = p_event_id
    ORDER BY start_time ASC
  LOOP
    PERFORM public._schedule_event_live_activity_job(
      p_event_id, v_schedule.id, 'start', v_schedule.start_time
    );

    v_end_at := coalesce(v_schedule.end_time, v_schedule.start_time);
    PERFORM public._schedule_event_live_activity_job(
      p_event_id, v_schedule.id, 'end', v_end_at
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.sync_event_live_activity_jobs(uuid) IS
  'Plant Einmal-pg_cron-Jobs für Event-Live-Activities (nur type=event).';

CREATE OR REPLACE FUNCTION public._event_is_type_event(p_type text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(trim(coalesce(p_type, ''))) = 'event';
$$;

CREATE OR REPLACE FUNCTION public._invoke_schedule_live_activity_change(
  p_body jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault
AS $$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets
  WHERE name = 'schedule_live_activity_cron_secret'
  LIMIT 1;

  IF v_secret IS NULL OR v_secret = '' THEN
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/schedule-live-activity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', v_secret
    ),
    body := p_body
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_schedule_live_activity_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_event_id uuid;
  request_body jsonb;
  parent_type text;
  should_sync boolean := false;
  should_notify_change boolean := false;
BEGIN
  IF TG_TABLE_NAME = 'calendar_events' THEN
    IF TG_OP = 'INSERT' THEN
      IF NOT public._event_is_type_event(NEW.type::text) THEN
        RETURN NEW;
      END IF;
      PERFORM public.sync_event_live_activity_jobs(NEW.id);
      RETURN NEW;
    END IF;

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

      IF public._event_is_type_event(OLD.type::text)
         OR public._event_is_type_event(NEW.type::text) THEN
        should_sync := true;
      END IF;

      IF public._event_is_type_event(NEW.type::text) THEN
        should_notify_change := true;
        target_event_id := NEW.id;
        request_body := jsonb_build_object(
          'mode', 'change',
          'event_id', target_event_id,
          'op', TG_OP,
          'source', 'calendar_events'
        );
      ELSIF public._event_is_type_event(OLD.type::text) THEN
        should_notify_change := true;
        target_event_id := OLD.id;
        request_body := jsonb_build_object(
          'mode', 'change',
          'event_id', target_event_id,
          'op', TG_OP,
          'source', 'calendar_events',
          'event_snapshot', jsonb_build_object(
            'id', OLD.id,
            'event_name', OLD.event_name,
            'start_time', OLD.start_time,
            'end_time', OLD.end_time,
            'location', OLD.location,
            'choir', OLD.choir,
            'voices', OLD.voices,
            'type', OLD.type::text
          )
        );
      END IF;

      IF should_sync THEN
        PERFORM public.sync_event_live_activity_jobs(NEW.id);
        IF public._event_is_type_event(OLD.type::text)
           AND NOT public._event_is_type_event(NEW.type::text) THEN
          PERFORM public._clear_event_live_activity_jobs(OLD.id);
        END IF;
      END IF;

      IF should_notify_change THEN
        PERFORM public._invoke_schedule_live_activity_change(request_body);
      END IF;

      RETURN NEW;
    END IF;

    IF TG_OP = 'DELETE' THEN
      IF NOT public._event_is_type_event(OLD.type::text) THEN
        RETURN OLD;
      END IF;

      PERFORM public._clear_event_live_activity_jobs(OLD.id);
      target_event_id := OLD.id;
      request_body := jsonb_build_object(
        'mode', 'change',
        'event_id', target_event_id,
        'op', TG_OP,
        'source', 'calendar_events',
        'event_snapshot', jsonb_build_object(
          'id', OLD.id,
          'event_name', OLD.event_name,
          'start_time', OLD.start_time,
          'end_time', OLD.end_time,
          'location', OLD.location,
          'choir', OLD.choir,
          'voices', OLD.voices,
          'type', OLD.type::text
        )
      );
      PERFORM public._invoke_schedule_live_activity_change(request_body);
      RETURN OLD;
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

    SELECT type::text INTO parent_type
    FROM public.calendar_events
    WHERE id = target_event_id;

    IF NOT FOUND OR NOT public._event_is_type_event(parent_type) THEN
      RETURN COALESCE(NEW, OLD);
    END IF;

    PERFORM public.sync_event_live_activity_jobs(target_event_id);

    request_body := jsonb_build_object(
      'mode', 'change',
      'event_id', target_event_id,
      'op', TG_OP,
      'source', 'event_schedules'
    );
    PERFORM public._invoke_schedule_live_activity_change(request_body);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

COMMENT ON FUNCTION public.trigger_schedule_live_activity_change() IS
  'Sync + sofortiger Change-Handler für Event-Live-Activities (nur type=event).';

DROP TRIGGER IF EXISTS schedule_live_activity_calendar_events_change
  ON public.calendar_events;
CREATE TRIGGER schedule_live_activity_calendar_events_change
  AFTER INSERT OR UPDATE OR DELETE ON public.calendar_events
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_schedule_live_activity_change();

DROP TRIGGER IF EXISTS schedule_live_activity_event_schedules_change
  ON public.event_schedules;
CREATE TRIGGER schedule_live_activity_event_schedules_change
  AFTER INSERT OR UPDATE OR DELETE ON public.event_schedules
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_schedule_live_activity_change();

-- Bestehende zukünftige Events type=event nachplanen.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT id
    FROM public.calendar_events
    WHERE lower(trim(type::text)) = 'event'
      AND end_time > now()
  LOOP
    PERFORM public.sync_event_live_activity_jobs(r.id);
  END LOOP;
END $$;
