-- Mehrere FCM-Geräte pro Admin (statt nur profiles.fcm_token).

CREATE TABLE IF NOT EXISTS public.profile_push_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS profile_push_devices_user_id_idx
  ON public.profile_push_devices (user_id);

COMMENT ON TABLE public.profile_push_devices IS
  'FCM-Tokens pro Gerät/Installation. Edge Function notify-admins liest mit service_role.';

ALTER TABLE public.profile_push_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_push_devices_select_own ON public.profile_push_devices;
CREATE POLICY profile_push_devices_select_own ON public.profile_push_devices
  FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS profile_push_devices_insert_own ON public.profile_push_devices;
CREATE POLICY profile_push_devices_insert_own ON public.profile_push_devices
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS profile_push_devices_update_own ON public.profile_push_devices;
CREATE POLICY profile_push_devices_update_own ON public.profile_push_devices
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS profile_push_devices_delete_own ON public.profile_push_devices;
CREATE POLICY profile_push_devices_delete_own ON public.profile_push_devices
  FOR DELETE
  USING (user_id = auth.uid());

-- Bestehende Einzel-Tokens aus profiles übernehmen (einmalig).
INSERT INTO public.profile_push_devices (user_id, device_id, fcm_token, platform, updated_at)
SELECT
  id,
  'legacy-migration',
  fcm_token,
  'ios',
  COALESCE(fcm_token_updated_at, now())
FROM public.profiles
WHERE fcm_token IS NOT NULL
  AND trim(fcm_token) <> ''
ON CONFLICT (user_id, device_id) DO UPDATE SET
  fcm_token = EXCLUDED.fcm_token,
  updated_at = EXCLUDED.updated_at;
