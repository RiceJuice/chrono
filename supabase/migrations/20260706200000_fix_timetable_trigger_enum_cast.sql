-- COALESCE(enum, '') wirft bei calendar_events.type = 'event'; explizit ::text casten.

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
      CASE WHEN TG_OP = 'DELETE' THEN OLD.type::text ELSE NEW.type::text END,
      ''
    );
  ELSIF TG_TABLE_NAME = 'calendar_series' THEN
    row_type := COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN OLD.type::text ELSE NEW.type::text END,
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
