import type { createClient } from "npm:@supabase/supabase-js@2.49.1";
import type { CalendarEventRow, DeviceRow, ProfileRow } from "./types.ts";

export function asProfile(
  raw: ProfileRow | ProfileRow[] | null | undefined,
): ProfileRow | null {
  if (raw == null) return null;
  if (Array.isArray(raw)) return raw[0] ?? null;
  return raw;
}

export function normalizeText(value: string | null | undefined): string | null {
  if (value == null) return null;
  const trimmed = value.trim().toLowerCase();
  return trimmed.length > 0 ? trimmed : null;
}

export function parseAudienceTokens(raw: string | string[] | null | undefined): string[] {
  if (raw == null) return [];
  if (Array.isArray(raw)) {
    return raw
      .map((v) => normalizeText(String(v)))
      .filter((v): v is string => v != null);
  }
  if (typeof raw !== "string") return [];
  const cleaned = raw.replace(/[{}"]/g, "");
  return cleaned
    .split(",")
    .map((v) => normalizeText(v))
    .filter((v): v is string => v != null);
}

export function profileMatchesEvent(
  profile: ProfileRow,
  event: CalendarEventRow,
): boolean {
  const eventChoirs = parseAudienceTokens(event.choir);
  const eventVoices = parseAudienceTokens(event.voices);
  const profileChoir = normalizeText(profile.choir);
  const profileVoice = normalizeText(profile.voice);

  if (eventChoirs.length > 0) {
    if (!profileChoir || !eventChoirs.includes(profileChoir)) return false;
  }

  if (eventVoices.length > 0) {
    if (!profileVoice || profileVoice === "unknown") return false;
    if (!eventVoices.includes(profileVoice)) return false;
  }

  return true;
}

export function resolveSegmentStartEvent(device: DeviceRow): "start" | "update" {
  const liveToken = device.live_activity_push_token?.trim();
  return liveToken && liveToken.length > 0 ? "update" : "start";
}

export async function loadEventDevices(
  supabase: ReturnType<typeof createClient>,
  event: CalendarEventRow,
): Promise<DeviceRow[]> {
  const { data, error } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, device_id, fcm_token, platform, schedule_filter, push_to_start_token, live_activity_push_token, profiles!inner(id, choir, voice)",
    )
    .not("fcm_token", "is", null)
    .or(
      "push_to_start_token.not.is.null,live_activity_push_token.not.is.null",
    );

  if (error) throw new Error(error.message);

  return ((data ?? []) as DeviceRow[]).filter((device) => {
    const profile = asProfile(device.profiles);
    return profile != null && profileMatchesEvent(profile, event);
  });
}

export async function loadTimetableDevices(
  supabase: ReturnType<typeof createClient>,
  userId: string,
): Promise<DeviceRow[]> {
  const { data, error } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, device_id, fcm_token, platform, schedule_filter, push_to_start_token, live_activity_push_token, profiles!inner(id, choir, voice, class_name, schooltrack)",
    )
    .eq("user_id", userId)
    .not("fcm_token", "is", null)
    .or(
      "push_to_start_token.not.is.null,live_activity_push_token.not.is.null",
    );

  if (error) throw new Error(error.message);
  return (data ?? []) as DeviceRow[];
}
