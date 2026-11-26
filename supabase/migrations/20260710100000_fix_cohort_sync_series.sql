-- Kohorten-Sync wieder mit Serien-Expansion (_fill_la_timetable_segments),
-- die in 20260709100000 versehentlich durch reine calendar_events-Abfrage
-- ersetzt wurde.

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

COMMENT ON FUNCTION public.sync_timetable_cohort_live_activity_jobs(text, text, date) IS
  'Plant Stundenplan-Live-Activity-Jobs pro Kohorte inkl. calendar_series (RRULE).';

-- Manueller Neuplan für den 14-Tage-Horizont.
SELECT public.sync_timetable_jobs_horizon();
