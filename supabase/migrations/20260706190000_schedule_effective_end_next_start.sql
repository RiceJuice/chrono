-- Ablaufplan ohne Endzeit: Segment läuft bis Start des nächsten Punkts.

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
    SELECT
      id,
      start_time,
      end_time,
      LEAD(start_time) OVER (ORDER BY start_time ASC) AS next_start
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
    v_last_end := coalesce(
      v_schedule.end_time,
      v_schedule.next_start,
      v_schedule.start_time + interval '45 minutes'
    );

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
