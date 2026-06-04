-- Referenz: Push-Geräte (mehrere pro Admin)
-- Migration: supabase/migrations/*_profile_push_devices.sql

CREATE TABLE IF NOT EXISTS public.profile_push_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  fcm_token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_id)
);

-- Legacy (nicht mehr von der App beschrieben):
-- profiles.fcm_token, profiles.fcm_token_updated_at
