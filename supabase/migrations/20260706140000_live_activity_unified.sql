-- Vereinheitlichte Live-Activity-Job-Planung (Event + Stundenplan), ohne Polling-Cron.

CREATE TABLE IF NOT EXISTS public.live_activity_job_errors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  context text NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS live_activity_job_errors_created_at_idx
  ON public.live_activity_job_errors (created_at);

COMMENT ON TABLE public.live_activity_job_errors IS
  'Diagnose-Log für fehlgeschlagene Live-Activity-Job-Planung (z. B. fehlendes Vault-Secret).';

CREATE TABLE IF NOT EXISTS public.live_activity_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL CHECK (kind IN ('event', 'timetable')),
  reference_id text NOT NULL,
  user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  schedule_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  action text NOT NULL CHECK (action IN ('start', 'update', 'end')),
  run_at timestamptz NOT NULL,
  cron_jobname text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT live_activity_jobs_dedup_unique UNIQUE (
    kind, reference_id, user_id, schedule_id, action, run_at
  )
);

CREATE INDEX IF NOT EXISTS live_activity_jobs_reference_idx
  ON public.live_activity_jobs (kind, reference_id);

CREATE INDEX IF NOT EXISTS live_activity_jobs_run_at_idx
  ON public.live_activity_jobs (run_at);

COMMENT ON TABLE public.live_activity_jobs IS
  'Einmal-pg_cron-Jobs für Live Activities (Event-Ablaufplan + Stundenplan).';

-- Bestehende Event-Jobs übernehmen.
INSERT INTO public.live_activity_jobs (
  id, kind, reference_id, user_id, schedule_id, action, run_at, cron_jobname, created_at
)
SELECT
  id,
  'event',
  event_id::text,
  '00000000-0000-0000-0000-000000000000'::uuid,
  coalesce(schedule_id, '00000000-0000-0000-0000-000000000000'::uuid),
  action,
  run_at,
  cron_jobname,
  created_at
FROM public.event_live_activity_jobs
ON CONFLICT ON CONSTRAINT live_activity_jobs_dedup_unique DO NOTHING;

DROP TABLE IF EXISTS public.event_live_activity_jobs;

CREATE OR REPLACE FUNCTION public._log_live_activity_job_error(
  p_context text,
  p_message text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.live_activity_job_errors (context, message)
  VALUES (p_context, p_message);
  RAISE WARNING 'live_activity_job: % — %', p_context, p_message;
END;
$$;

CREATE OR REPLACE FUNCTION public._live_activity_vault_secret()
RETURNS text
LANGUAGE plpgsql
STABLE
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
    PERFORM public._log_live_activity_job_error(
      'vault_secret',
      'schedule_live_activity_cron_secret fehlt im Vault'
    );
    RETURN NULL;
  END IF;

  RETURN v_secret;
END;
$$;

CREATE OR REPLACE FUNCTION public._clear_live_activity_jobs(
  p_kind text,
  p_reference_id text,
  p_user_id uuid DEFAULT NULL
)
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
    FROM public.live_activity_jobs
    WHERE kind = p_kind
      AND reference_id = p_reference_id
      AND (
        p_user_id IS NULL
        OR p_user_id = '00000000-0000-0000-0000-000000000000'::uuid
        OR user_id = p_user_id
      )
  LOOP
    BEGIN
      PERFORM cron.unschedule(r.cron_jobname);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  DELETE FROM public.live_activity_jobs
  WHERE kind = p_kind
    AND reference_id = p_reference_id
    AND (
      p_user_id IS NULL
      OR user_id IS NOT DISTINCT FROM p_user_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION public._schedule_live_activity_job(
  p_kind text,
  p_reference_id text,
  p_user_id uuid,
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

  v_secret := public._live_activity_vault_secret();
  IF v_secret IS NULL THEN
    RETURN;
  END IF;

  v_job_id := gen_random_uuid();
  v_jobname := 'la-' || replace(v_job_id::text, '-', '');
  v_cron_expr := public._timestamptz_to_cron_expr(p_run_at);

  v_body := jsonb_build_object(
    'mode', 'dispatch',
    'kind', p_kind,
    'reference_id', p_reference_id,
    'action', p_action,
    'job_id', v_job_id
  );

  IF p_user_id IS NOT NULL
     AND p_user_id <> '00000000-0000-0000-0000-000000000000'::uuid THEN
    v_body := v_body || jsonb_build_object('user_id', p_user_id);
  END IF;

  IF p_schedule_id IS NOT NULL
     AND p_schedule_id <> '00000000-0000-0000-0000-000000000000'::uuid THEN
    v_body := v_body || jsonb_build_object('schedule_id', p_schedule_id);
  END IF;

  BEGIN
    INSERT INTO public.live_activity_jobs (
      id, kind, reference_id, user_id, schedule_id, action, run_at, cron_jobname
    ) VALUES (
      v_job_id,
      p_kind,
      p_reference_id,
      coalesce(p_user_id, '00000000-0000-0000-0000-000000000000'::uuid),
      coalesce(p_schedule_id, '00000000-0000-0000-0000-000000000000'::uuid),
      p_action,
      p_run_at,
      v_jobname
    );
  EXCEPTION
    WHEN unique_violation THEN
      RETURN;
  END;

  PERFORM cron.schedule(
    v_jobname,
    v_cron_expr,
    format(
      $job$
      SELECT net.http_post(
        url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/live-activity',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-cron-secret', %L
        ),
        body := %L::jsonb
      );
      SELECT cron.unschedule(%L);
      DELETE FROM public.live_activity_jobs WHERE id = %L::uuid;
      $job$,
      v_secret,
      v_body::text,
      v_jobname,
      v_job_id
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public._event_is_type_event(p_type text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(trim(coalesce(p_type, ''))) = 'event';
$$;

CREATE OR REPLACE FUNCTION public._lesson_matches_profile(
  p_entry_class text,
  p_entry_schooltrack text,
  p_profile_class text,
  p_profile_schooltrack text
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    (
      trim(coalesce(p_entry_class, '')) = ''
      OR (
        trim(coalesce(p_profile_class, '')) <> ''
        AND lower(trim(p_entry_class)) = lower(trim(p_profile_class))
      )
    )
    AND (
      lower(trim(coalesce(p_entry_schooltrack, ''))) IN ('', 'unknown')
      OR (
        trim(coalesce(p_profile_schooltrack, '')) <> ''
        AND lower(trim(p_entry_schooltrack)) = lower(trim(p_profile_schooltrack))
      )
    );
$$;

CREATE OR REPLACE FUNCTION public._is_lunch_meal(p_start timestamptz)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT EXTRACT(HOUR FROM p_start AT TIME ZONE 'Europe/Berlin') < 15;
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
  v_last_schedule_id uuid;
  v_last_end timestamptz;
  v_is_first boolean := true;
BEGIN
  PERFORM public._clear_live_activity_jobs('event', p_event_id::text, NULL);

  SELECT id, type, start_time, end_time
  INTO v_event
  FROM public.calendar_events
  WHERE id = p_event_id;

  IF NOT FOUND OR NOT public._event_is_type_event(v_event.type::text) THEN
    RETURN;
  END IF;

  IF v_event.end_time IS NOT NULL AND v_event.end_time <= now() THEN
    RETURN;
  END IF;

  SELECT count(*) INTO v_schedule_count
  FROM public.event_schedules
  WHERE event_id = p_event_id;

  IF v_schedule_count = 0 THEN
    PERFORM public._schedule_live_activity_job(
      'event', p_event_id::text, NULL, NULL, 'start', v_event.start_time
    );
    PERFORM public._schedule_live_activity_job(
      'event', p_event_id::text, NULL, NULL, 'end', v_event.end_time
    );
    RETURN;
  END IF;

  FOR v_schedule IN
    SELECT id, start_time, end_time
    FROM public.event_schedules
    WHERE event_id = p_event_id
    ORDER BY start_time ASC
  LOOP
    IF v_is_first THEN
      PERFORM public._schedule_live_activity_job(
        'event', p_event_id::text, NULL, v_schedule.id, 'start', v_schedule.start_time
      );
      v_is_first := false;
    ELSE
      PERFORM public._schedule_live_activity_job(
        'event', p_event_id::text, NULL, v_schedule.id, 'update', v_schedule.start_time
      );
    END IF;

    v_last_schedule_id := v_schedule.id;
    v_last_end := coalesce(v_schedule.end_time, v_schedule.start_time + interval '45 minutes');

    PERFORM public._schedule_live_activity_job(
      'event', p_event_id::text, NULL, v_schedule.id, 'update', v_last_end
    );
  END LOOP;

  IF v_last_schedule_id IS NOT NULL AND v_last_end IS NOT NULL THEN
    PERFORM public._schedule_live_activity_job(
      'event', p_event_id::text, NULL, v_last_schedule_id, 'end', v_last_end
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_timetable_live_activity_jobs(
  p_user_id uuid,
  p_day_date date
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile record;
  v_day_key text;
  v_bounds_start timestamptz;
  v_bounds_end timestamptz;
  v_segment record;
  v_segments_count int := 0;
  v_first_start timestamptz;
  v_activity_start timestamptz;
  v_last_end timestamptz;
  v_is_first boolean := true;
  v_prev_end timestamptz;
BEGIN
  v_day_key := to_char(p_day_date, 'YYYY-MM-DD');
  PERFORM public._clear_live_activity_jobs('timetable', v_day_key, p_user_id);

  SELECT id, class_name, schooltrack
  INTO v_profile
  FROM public.profiles
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  v_bounds_start := (p_day_date::text || 'T00:00:00')::timestamptz AT TIME ZONE 'Europe/Berlin';
  v_bounds_end := (p_day_date::text || 'T23:59:59')::timestamptz AT TIME ZONE 'Europe/Berlin';

  CREATE TEMP TABLE IF NOT EXISTS _la_timetable_segments (
    id uuid,
    seg_type text,
    start_time timestamptz,
    end_time timestamptz
  ) ON COMMIT DROP;

  TRUNCATE _la_timetable_segments;

  INSERT INTO _la_timetable_segments (id, seg_type, start_time, end_time)
  SELECT
    ce.id,
    ce.type::text,
    ce.start_time,
    coalesce(ce.end_time, ce.start_time + interval '45 minutes')
  FROM public.calendar_events ce
  WHERE ce.type IN ('lesson', 'meal')
    AND ce.start_time >= v_bounds_start
    AND ce.start_time <= v_bounds_end
    AND (
      ce.type = 'lesson'
      OR public._is_lunch_meal(ce.start_time)
    )
    AND public._lesson_matches_profile(
      ce.class::text,
      ce.schooltrack::text,
      v_profile.class_name,
      v_profile.schooltrack::text
    )
  ORDER BY ce.start_time ASC;

  SELECT count(*) INTO v_segments_count FROM _la_timetable_segments;
  IF v_segments_count = 0 THEN
    RETURN;
  END IF;

  SELECT min(start_time) INTO v_first_start FROM _la_timetable_segments;
  v_activity_start := v_first_start - interval '15 minutes';

  IF v_activity_start > now() THEN
    PERFORM public._schedule_live_activity_job(
      'timetable', v_day_key, p_user_id, NULL, 'start', v_activity_start
    );
  END IF;

  v_prev_end := NULL;
  FOR v_segment IN
    SELECT id, seg_type, start_time, end_time
    FROM _la_timetable_segments
    ORDER BY start_time ASC
  LOOP
    IF v_prev_end IS NOT NULL AND v_prev_end > now() THEN
      PERFORM public._schedule_live_activity_job(
        'timetable', v_day_key, p_user_id, v_segment.id, 'update', v_prev_end
      );
    END IF;

    IF NOT v_is_first AND v_segment.start_time > now() THEN
      PERFORM public._schedule_live_activity_job(
        'timetable', v_day_key, p_user_id, v_segment.id, 'update', v_segment.start_time
      );
    END IF;

    v_last_end := v_segment.end_time;
    v_prev_end := v_segment.end_time;
    v_is_first := false;
  END LOOP;

  IF v_last_end IS NOT NULL AND v_last_end > now() THEN
    PERFORM public._schedule_live_activity_job(
      'timetable', v_day_key, p_user_id, NULL, 'end', v_last_end
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_all_timetable_jobs_for_day(p_day_date date)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
BEGIN
  IF p_day_date < current_date OR p_day_date > current_date + 14 THEN
    RETURN;
  END IF;

  FOR r IN
    SELECT DISTINCT p.id AS user_id
    FROM public.profiles p
    WHERE EXISTS (
      SELECT 1
      FROM public.profile_push_devices d
      WHERE d.user_id = p.id
        AND d.fcm_token IS NOT NULL
    )
  LOOP
    PERFORM public.sync_timetable_live_activity_jobs(r.user_id, p_day_date);
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_timetable_jobs_horizon()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  d date;
BEGIN
  FOR d IN
    SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
  LOOP
    PERFORM public.sync_all_timetable_jobs_for_day(d);
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public._invoke_live_activity_change(p_body jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault
AS $$
DECLARE
  v_secret text;
BEGIN
  v_secret := public._live_activity_vault_secret();
  IF v_secret IS NULL THEN
    RETURN;
  END IF;

  PERFORM net.http_post(
    url := 'https://chrbvfaknykaycwumuba.supabase.co/functions/v1/live-activity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', v_secret
    ),
    body := p_body
  );
END;
$$;

CREATE OR REPLACE FUNCTION public._clear_event_live_activity_jobs(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._clear_live_activity_jobs('event', p_event_id::text, NULL);
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
SET search_path = public
AS $$
BEGIN
  PERFORM public._schedule_live_activity_job(
    'event',
    p_event_id::text,
    NULL,
    p_schedule_id,
    p_action,
    p_run_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public._invoke_schedule_live_activity_change(p_body jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public._invoke_live_activity_change(
    p_body || jsonb_build_object('kind', 'event')
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
  d date;
BEGIN
  IF TG_TABLE_NAME = 'calendar_events' THEN
    IF TG_OP = 'INSERT' THEN
      IF public._event_is_type_event(NEW.type::text) THEN
        PERFORM public.sync_event_live_activity_jobs(NEW.id);
      ELSIF NEW.type IN ('lesson', 'meal') THEN
        FOR d IN
          SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
        LOOP
          PERFORM public.sync_all_timetable_jobs_for_day(d);
        END LOOP;
      END IF;
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
          'kind', 'event',
          'reference_id', target_event_id::text,
          'op', TG_OP,
          'source', 'calendar_events'
        );
      ELSIF public._event_is_type_event(OLD.type::text) THEN
        should_notify_change := true;
        target_event_id := OLD.id;
        request_body := jsonb_build_object(
          'mode', 'change',
          'kind', 'event',
          'reference_id', target_event_id::text,
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

      IF NEW.type IN ('lesson', 'meal') OR OLD.type IN ('lesson', 'meal') THEN
        FOR d IN
          SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
        LOOP
          PERFORM public.sync_all_timetable_jobs_for_day(d);
        END LOOP;
        PERFORM public._invoke_live_activity_change(jsonb_build_object(
          'mode', 'change',
          'kind', 'timetable',
          'reference_id', to_char(current_date, 'YYYY-MM-DD')
        ));
      END IF;

      IF should_notify_change THEN
        PERFORM public._invoke_schedule_live_activity_change(request_body);
      END IF;

      RETURN NEW;
    END IF;

    IF TG_OP = 'DELETE' THEN
      IF public._event_is_type_event(OLD.type::text) THEN
        PERFORM public._clear_event_live_activity_jobs(OLD.id);
        PERFORM public._invoke_schedule_live_activity_change(jsonb_build_object(
          'mode', 'change',
          'kind', 'event',
          'reference_id', OLD.id::text,
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
        ));
      ELSIF OLD.type IN ('lesson', 'meal') THEN
        FOR d IN
          SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
        LOOP
          PERFORM public.sync_all_timetable_jobs_for_day(d);
        END LOOP;
      END IF;
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
    PERFORM public._invoke_schedule_live_activity_change(jsonb_build_object(
      'mode', 'change',
      'kind', 'event',
      'reference_id', target_event_id::text,
      'op', TG_OP,
      'source', 'event_schedules'
    ));
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_timetable_live_activity_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row_type text;
  d date;
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

  FOR d IN
    SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
  LOOP
    PERFORM public.sync_all_timetable_jobs_for_day(d);
  END LOOP;

  PERFORM public._invoke_live_activity_change(jsonb_build_object(
    'mode', 'change',
    'kind', 'timetable',
    'reference_id', to_char(current_date, 'YYYY-MM-DD')
  ));

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_profile_timetable_live_activity_sync()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  d date;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF (OLD.class_name, OLD.schooltrack, OLD.choir, OLD.voice)
       IS NOT DISTINCT FROM
       (NEW.class_name, NEW.schooltrack, NEW.choir, NEW.voice) THEN
      RETURN NEW;
    END IF;
  END IF;

  FOR d IN
    SELECT generate_series(current_date, current_date + 14, interval '1 day')::date
  LOOP
    PERFORM public.sync_timetable_live_activity_jobs(NEW.id, d);
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profile_timetable_live_activity_sync ON public.profiles;
CREATE TRIGGER profile_timetable_live_activity_sync
  AFTER UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_profile_timetable_live_activity_sync();

-- 15-Minuten-Polling entfernen.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'timetable-live-activity') THEN
    PERFORM cron.unschedule(jobid)
    FROM cron.job
    WHERE jobname = 'timetable-live-activity';
  END IF;
END $$;

-- Bestehende Daten nachplanen.
DO $$
DECLARE
  r record;
  d date;
BEGIN
  FOR r IN
    SELECT id
    FROM public.calendar_events
    WHERE lower(trim(type::text)) = 'event'
      AND end_time > now()
  LOOP
    PERFORM public.sync_event_live_activity_jobs(r.id);
  END LOOP;

  PERFORM public.sync_timetable_jobs_horizon();
END $$;
