-- Stundenplan-Dispatch: ein Cron-Job pro Kohorte (Klasse+Zweig) statt pro Nutzer.
-- Edge Function verarbeitet alle Geräte der Kohorte in einem Aufruf (parallel).

CREATE OR REPLACE FUNCTION public._schedule_live_activity_job(
  p_kind text,
  p_reference_id text,
  p_user_id uuid,
  p_schedule_id uuid,
  p_action text,
  p_run_at timestamptz,
  p_class_name text DEFAULT NULL,
  p_schooltrack text DEFAULT NULL
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

  IF p_class_name IS NOT NULL OR p_schooltrack IS NOT NULL THEN
    v_body := v_body || jsonb_build_object(
      'class_name', p_class_name,
      'schooltrack', p_schooltrack
    );
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

CREATE OR REPLACE FUNCTION public._timetable_cohort_reference_id(
  p_day_date date,
  p_class_name text,
  p_schooltrack text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT to_char(p_day_date, 'YYYY-MM-DD')
    || '|' || coalesce(p_class_name, '')
    || '|' || coalesce(p_schooltrack, '');
$$;

CREATE OR REPLACE FUNCTION public.sync_timetable_cohort_live_activity_jobs(
  p_class_name text,
  p_schooltrack text,
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
  v_ref_key text;
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
  v_ref_key := public._timetable_cohort_reference_id(p_day_date, p_class_name, p_schooltrack);

  PERFORM public._clear_live_activity_jobs('timetable', v_ref_key, NULL);

  SELECT id, class_name, schooltrack
  INTO v_profile
  FROM public.profiles p
  WHERE p.class_name IS NOT DISTINCT FROM p_class_name
    AND p.schooltrack::text IS NOT DISTINCT FROM p_schooltrack
    AND EXISTS (
      SELECT 1
      FROM public.profile_push_devices d
      WHERE d.user_id = p.id
        AND d.fcm_token IS NOT NULL
    )
  LIMIT 1;

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
      'timetable', v_ref_key, NULL, NULL, 'start', v_activity_start,
      p_class_name, p_schooltrack
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
        'timetable', v_ref_key, NULL, v_segment.id, 'update', v_prev_end,
        p_class_name, p_schooltrack
      );
    END IF;

    IF NOT v_is_first AND v_segment.start_time > now() THEN
      PERFORM public._schedule_live_activity_job(
        'timetable', v_ref_key, NULL, v_segment.id, 'update', v_segment.start_time,
        p_class_name, p_schooltrack
      );
    END IF;

    v_last_end := v_segment.end_time;
    v_prev_end := v_segment.end_time;
    v_is_first := false;
  END LOOP;

  IF v_last_end IS NOT NULL AND v_last_end > now() THEN
    PERFORM public._schedule_live_activity_job(
      'timetable', v_ref_key, NULL, NULL, 'end', v_last_end,
      p_class_name, p_schooltrack
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
BEGIN
  SELECT class_name, schooltrack::text
  INTO v_profile
  FROM public.profiles
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  PERFORM public.sync_timetable_cohort_live_activity_jobs(
    v_profile.class_name,
    v_profile.schooltrack,
    p_day_date
  );
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
    SELECT DISTINCT p.class_name, p.schooltrack::text AS schooltrack
    FROM public.profiles p
    WHERE EXISTS (
      SELECT 1
      FROM public.profile_push_devices d
      WHERE d.user_id = p.id
        AND d.fcm_token IS NOT NULL
    )
  LOOP
    PERFORM public.sync_timetable_cohort_live_activity_jobs(
      r.class_name,
      r.schooltrack,
      p_day_date
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.sync_timetable_cohort_live_activity_jobs(text, text, date) IS
  'Plant Stundenplan-Live-Activity-Jobs pro Kohorte (Klasse+Zweig), nicht pro Nutzer.';

-- Alte per-Nutzer-Stundenplan-Jobs entfernen (reference_id ohne "|" und user_id gesetzt).
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT cron_jobname
    FROM public.live_activity_jobs
    WHERE kind = 'timetable'
      AND reference_id NOT LIKE '%|%'
      AND user_id <> '00000000-0000-0000-0000-000000000000'::uuid
  LOOP
    BEGIN
      PERFORM cron.unschedule(r.cron_jobname);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
  END LOOP;

  DELETE FROM public.live_activity_jobs
  WHERE kind = 'timetable'
    AND reference_id NOT LIKE '%|%'
    AND user_id <> '00000000-0000-0000-0000-000000000000'::uuid;
END $$;

-- Kohorten-Jobs neu planen.
SELECT public.sync_timetable_jobs_horizon();
