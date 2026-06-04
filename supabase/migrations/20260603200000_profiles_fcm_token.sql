-- FCM device tokens for admin push notifications (n8n → notify-admins → FCM).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token text,
  ADD COLUMN IF NOT EXISTS fcm_token_updated_at timestamptz;

COMMENT ON COLUMN public.profiles.fcm_token IS
  'FCM device token; nur vom Gerät des Users gesetzt. Edge Function liest mit service_role.';
