-- Zielgerichtete Device-Abfrage für notify-event-change (kein Full-Table-Scan).

CREATE OR REPLACE FUNCTION public._audience_has_criteria(p_audience jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    coalesce(nullif(trim(p_audience->>'choir'), ''), '') <> ''
    OR jsonb_array_length(coalesce(p_audience->'voices', '[]'::jsonb)) > 0
    OR coalesce(nullif(trim(p_audience->>'schooltrack'), ''), '') <> ''
    OR coalesce(nullif(trim(p_audience->>'class_name'), ''), '') <> ''
    OR coalesce(nullif(trim(p_audience->>'diet'), ''), '') <> '';
$$;

CREATE OR REPLACE FUNCTION public._profile_matches_audience(
  p_profile public.profiles,
  p_audience jsonb,
  p_event_type text
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_choir text;
  v_voice text;
  v_schooltrack text;
  v_class_name text;
  v_diet text;
BEGIN
  IF NOT public._audience_has_criteria(p_audience) THEN
    RETURN false;
  END IF;

  v_choir := nullif(trim(p_audience->>'choir'), '');
  IF v_choir IS NOT NULL THEN
    IF lower(trim(coalesce(p_profile.choir, ''))) <> lower(v_choir) THEN
      RETURN false;
    END IF;
  END IF;

  IF jsonb_array_length(coalesce(p_audience->'voices', '[]'::jsonb)) > 0 THEN
    v_voice := lower(trim(coalesce(p_profile.voice, '')));
    IF v_voice = '' THEN
      RETURN false;
    END IF;
    IF NOT EXISTS (
      SELECT 1
      FROM jsonb_array_elements_text(coalesce(p_audience->'voices', '[]'::jsonb)) AS v(elem)
      WHERE lower(trim(v.elem)) = v_voice
    ) THEN
      RETURN false;
    END IF;
  END IF;

  v_schooltrack := nullif(trim(p_audience->>'schooltrack'), '');
  IF v_schooltrack IS NOT NULL THEN
    IF lower(trim(coalesce(p_profile.schooltrack::text, ''))) <> lower(v_schooltrack) THEN
      RETURN false;
    END IF;
  END IF;

  v_class_name := nullif(trim(p_audience->>'class_name'), '');
  IF v_class_name IS NOT NULL THEN
    IF lower(trim(coalesce(p_profile.class_name, ''))) <> lower(v_class_name) THEN
      RETURN false;
    END IF;
  END IF;

  v_diet := nullif(trim(p_audience->>'diet'), '');
  IF v_diet IS NOT NULL AND lower(trim(p_event_type)) = 'meal' THEN
    IF lower(trim(coalesce(p_profile.diet, ''))) <> lower(v_diet) THEN
      RETURN false;
    END IF;
  END IF;

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_event_change_targets(
  p_audience_before jsonb,
  p_audience_after jsonb,
  p_event_type text,
  p_editor_id uuid
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  fcm_token text,
  platform text,
  match_type text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    d.id,
    d.user_id,
    d.fcm_token,
    d.platform,
    CASE
      WHEN public._profile_matches_audience(p, p_audience_before, p_event_type)
           AND NOT public._profile_matches_audience(p, p_audience_after, p_event_type)
        THEN 'removed'
      WHEN public._profile_matches_audience(p, p_audience_after, p_event_type)
        THEN 'changed'
    END AS match_type
  FROM public.profile_push_devices d
  INNER JOIN public.profiles p ON p.id = d.user_id
  WHERE d.fcm_token IS NOT NULL
    AND trim(d.fcm_token) <> ''
    AND d.user_id <> p_editor_id
    AND (
      (
        public._profile_matches_audience(p, p_audience_before, p_event_type)
        AND NOT public._profile_matches_audience(p, p_audience_after, p_event_type)
      )
      OR public._profile_matches_audience(p, p_audience_after, p_event_type)
    );
$$;

REVOKE ALL ON FUNCTION public.notify_event_change_targets(jsonb, jsonb, text, uuid)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_event_change_targets(jsonb, jsonb, text, uuid)
  TO service_role;
