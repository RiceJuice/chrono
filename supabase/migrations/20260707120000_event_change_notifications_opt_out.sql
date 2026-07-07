-- Opt-out für Terminänderungs-Push über profiles.calendar_preferences.

CREATE OR REPLACE FUNCTION public._profile_event_change_notifications_enabled(
  p_preferences jsonb
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(
    CASE jsonb_typeof(p_preferences->'event_change_notifications')
      WHEN 'boolean' THEN (p_preferences->>'event_change_notifications')::boolean
      ELSE NULL
    END,
    true
  );
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
    AND public._profile_event_change_notifications_enabled(p.calendar_preferences) = true
    AND (
      (
        public._profile_matches_audience(p, p_audience_before, p_event_type)
        AND NOT public._profile_matches_audience(p, p_audience_after, p_event_type)
      )
      OR public._profile_matches_audience(p, p_audience_after, p_event_type)
    );
$$;

REVOKE ALL ON FUNCTION public._profile_event_change_notifications_enabled(jsonb)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public._profile_event_change_notifications_enabled(jsonb)
  TO service_role;

REVOKE ALL ON FUNCTION public.notify_event_change_targets(jsonb, jsonb, text, uuid)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_event_change_targets(jsonb, jsonb, text, uuid)
  TO service_role;
