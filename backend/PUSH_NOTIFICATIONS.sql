-- Referenz-SQL für FCM-Token auf profiles.
-- Kanonische Migration: supabase/migrations/*_profiles_fcm_token.sql

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token text,
  ADD COLUMN IF NOT EXISTS fcm_token_updated_at timestamptz;

COMMENT ON COLUMN public.profiles.fcm_token IS
  'FCM device token; nur vom Gerät des Users gesetzt. Edge Function liest mit service_role.';
