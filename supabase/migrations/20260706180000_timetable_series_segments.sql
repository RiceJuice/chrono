-- Stundenplan-Segmente: calendar_series (RRULE) + calendar_events (Overrides).

CREATE OR REPLACE FUNCTION public._rrule_byday_matches(
  p_rrule text,
  p_day date
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_rrule text;
  v_byday text;
  v_iso int;
  v_code text;
BEGIN
  v_rrule := upper(coalesce(p_rrule, ''));
  IF v_rrule = '' OR position('FREQ=WEEKLY' IN v_rrule) = 0 THEN
    RETURN false;
  END IF;

  v_iso := EXTRACT(ISODOW FROM p_day)::int;
  v_code := CASE v_iso
    WHEN 1 THEN 'MO'
    WHEN 2 THEN 'TU'
    WHEN 3 THEN 'WE'
    WHEN 4 THEN 'TH'
    WHEN 5 THEN 'FR'
    WHEN 6 THEN 'SA'
    WHEN 7 THEN 'SU'
    ELSE ''
  END;

  v_byday := substring(v_rrule FROM 'BYDAY=([^;]+)');
  IF v_byday IS NULL OR v_byday = '' THEN
    RETURN true;
  END IF;

  RETURN (',' || replace(v_byday, ' ', '') || ',') LIKE ('%,' || v_code || ',%');
END;
$$;

CREATE OR REPLACE FUNCTION public._rrule_weekly_interval(p_rrule text)
RETURNS int
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(
    nullif(substring(upper(coalesce(p_rrule, '')) FROM 'INTERVAL=([0-9]+)')::int, 0),
    1
  );
$$;

CREATE OR REPLACE FUNCTION public._series_occurs_on_local_day(
  p_rrule text,
  p_series_start date,
  p_series_end date,
  p_day date
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_weeks int;
  v_interval int;
BEGIN
  IF p_day < p_series_start THEN
    RETURN false;
  END IF;
  IF p_series_end IS NOT NULL AND p_day > p_series_end THEN
    RETURN false;
  END IF;
  IF NOT public._rrule_byday_matches(p_rrule, p_day) THEN
    RETURN false;
  END IF;

  v_interval := public._rrule_weekly_interval(p_rrule);
  IF v_interval <= 1 THEN
    RETURN true;
  END IF;

  v_weeks := ((p_day - p_series_start) / 7);
  RETURN (v_weeks % v_interval) = 0;
END;
$$;

CREATE OR REPLACE FUNCTION public._series_instant_on_day(
  p_day date,
  p_wall_time time with time zone
)
RETURNS timestamptz
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT timezone(
    'Europe/Berlin',
    (p_day::timestamp + (p_wall_time AT TIME ZONE 'Europe/Berlin')::time)
  );
$$;

CREATE OR REPLACE FUNCTION public._fill_la_timetable_segments(
  p_day_date date,
  p_profile_class text,
  p_profile_schooltrack text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_bounds_start timestamptz;
  v_bounds_end timestamptz;
BEGIN
  v_bounds_start := (p_day_date::text || 'T00:00:00')::timestamptz AT TIME ZONE 'Europe/Berlin';
  v_bounds_end := (p_day_date::text || 'T23:59:59')::timestamptz AT TIME ZONE 'Europe/Berlin';

  TRUNCATE _la_timetable_segments;

  INSERT INTO _la_timetable_segments (id, seg_type, start_time, end_time)
  SELECT
    cs.id,
    cs.type::text,
    public._series_instant_on_day(p_day_date, cs.start_time),
    coalesce(
      public._series_instant_on_day(p_day_date, cs.end_time),
      public._series_instant_on_day(p_day_date, cs.start_time) + interval '45 minutes'
    )
  FROM public.calendar_series cs
  WHERE cs.type IN ('lesson', 'meal')
    AND cs.series_start::date <= p_day_date
    AND (cs.series_end IS NULL OR cs.series_end::date >= p_day_date)
    AND public._series_occurs_on_local_day(
      cs.rrule::text,
      cs.series_start::date,
      cs.series_end::date,
      p_day_date
    )
    AND (
      cs.type = 'lesson'
      OR public._is_lunch_meal(public._series_instant_on_day(p_day_date, cs.start_time))
    )
    AND public._lesson_matches_profile(
      cs.class::text,
      cs.schooltrack::text,
      p_profile_class,
      p_profile_schooltrack
    );

  DELETE FROM _la_timetable_segments seg
  WHERE EXISTS (
    SELECT 1
    FROM public.calendar_events ce
    WHERE ce.series_id = seg.id
      AND ce.recurrence_id IS NOT NULL
      AND trim(ce.recurrence_id::text) <> ''
      AND ce.recurrence_id::timestamptz = seg.start_time
  );

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
      p_profile_class,
      p_profile_schooltrack
    )
    AND (
      ce.series_id IS NULL
      OR (
        ce.recurrence_id IS NOT NULL
        AND trim(ce.recurrence_id::text) <> ''
        AND ce.end_time > ce.start_time
      )
    );
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

  CREATE TEMP TABLE IF NOT EXISTS _la_timetable_segments (
    id uuid,
    seg_type text,
    start_time timestamptz,
    end_time timestamptz
  ) ON COMMIT DROP;

  PERFORM public._fill_la_timetable_segments(
    p_day_date,
    v_profile.class_name,
    v_profile.schooltrack::text
  );

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

-- Nachplanen mit Serien-Daten.
SELECT public.sync_timetable_jobs_horizon();
