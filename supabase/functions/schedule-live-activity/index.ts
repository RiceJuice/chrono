/**
 * pg_cron → FCM Live Activities für Ablaufplan-Segmente.
 */

import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  isUnregisteredTokenError,
  parseServiceAccountJson,
  sendLiveActivityFcm,
  type LiveActivityFcmEvent,
} from "../_shared/fcm_v1.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AudienceTokens = string | string[] | null | undefined;

type ScheduleRow = {
  id: string;
  event_id: string;
  title: string;
  location: string | null;
  start_time: string;
  end_time: string | null;
  choir: AudienceTokens;
  voices: AudienceTokens;
};

type CalendarEventRow = {
  id: string;
  event_name: string | null;
  choir: AudienceTokens;
  voices: AudienceTokens;
  type: string | null;
};

type ProfileRow = {
  id: string;
  choir: string | null;
  voice: string | null;
};

type DeviceRow = {
  id: string;
  user_id: string;
  device_id: string;
  fcm_token: string;
  platform: string;
  schedule_filter: string;
  push_to_start_token: string | null;
  live_activity_push_token: string | null;
  profiles: ProfileRow;
};

type Snapshot = {
  currentScheduleId: string;
  currentTitle: string;
  currentSubtitle: string;
  hasNext: boolean;
  nextTitle: string;
  nextSubtitle: string;
  segmentStartMs: number;
  segmentEndMs: number;
  isFinished: boolean;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeText(value: string | null | undefined): string | null {
  if (value == null) return null;
  const trimmed = value.trim().toLowerCase();
  return trimmed.length > 0 ? trimmed : null;
}

function parseAudienceTokens(raw: AudienceTokens): string[] {
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

function asProfile(
  raw: ProfileRow | ProfileRow[] | null | undefined,
): ProfileRow | null {
  if (raw == null) return null;
  if (Array.isArray(raw)) return raw[0] ?? null;
  return raw;
}

function profileMatchesEvent(
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

function scheduleVisibleForProfile(
  schedule: ScheduleRow,
  profile: ProfileRow,
  filter: string,
): boolean {
  if (filter !== "mine") return true;

  const profileChoir = normalizeText(profile.choir);
  const profileVoice = normalizeText(profile.voice);
  const scheduleChoirs = parseAudienceTokens(schedule.choir);
  const scheduleVoices = parseAudienceTokens(schedule.voices);

  if (scheduleChoirs.length === 0 && scheduleVoices.length === 0) {
    return true;
  }

  if (scheduleChoirs.length > 0) {
    if (!profileChoir || !scheduleChoirs.includes(profileChoir)) return false;
  }

  if (scheduleVoices.length > 0) {
    if (!profileVoice || !scheduleVoices.includes(profileVoice)) return false;
  }

  return true;
}

function effectiveEnd(schedule: ScheduleRow): Date {
  const endRaw = schedule.end_time ?? schedule.start_time;
  return new Date(endRaw);
}

function isSameLocalDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

function buildSnapshot(
  schedules: ScheduleRow[],
  now: Date,
): Snapshot | null {
  const visibleToday = schedules
    .filter((s) => isSameLocalDay(new Date(s.start_time), now))
    .sort((a, b) =>
      new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
    );

  if (visibleToday.length === 0) {
    return null;
  }

  const allPast = visibleToday.every((s) => effectiveEnd(s) <= now);
  if (allPast) {
    const last = visibleToday[visibleToday.length - 1];
    return {
      currentScheduleId: last.id,
      currentTitle: last.title,
      currentSubtitle: last.location ?? "",
      hasNext: false,
      nextTitle: "",
      nextSubtitle: "",
      segmentStartMs: new Date(last.start_time).getTime(),
      segmentEndMs: effectiveEnd(last).getTime(),
      isFinished: true,
    };
  }

  let currentIndex = -1;
  for (let i = 0; i < visibleToday.length; i++) {
    if (effectiveEnd(visibleToday[i]) > now) {
      currentIndex = i;
      break;
    }
  }
  if (currentIndex < 0) return null;

  const current = visibleToday[currentIndex];
  const next = currentIndex + 1 < visibleToday.length
    ? visibleToday[currentIndex + 1]
    : null;

  return {
    currentScheduleId: current.id,
    currentTitle: current.title,
    currentSubtitle: current.location ?? "",
    hasNext: next != null,
    nextTitle: next?.title ?? "",
    nextSubtitle: next?.location ?? "",
    segmentStartMs: new Date(current.start_time).getTime(),
    segmentEndMs: effectiveEnd(current).getTime(),
    isFinished: false,
  };
}

async function wasDispatched(
  supabase: ReturnType<typeof createClient>,
  scheduleId: string,
  userId: string,
  deviceId: string,
  action: LiveActivityFcmEvent,
): Promise<boolean> {
  const { data, error } = await supabase
    .from("schedule_live_activity_dispatches")
    .select("id")
    .eq("schedule_id", scheduleId)
    .eq("user_id", userId)
    .eq("device_id", deviceId)
    .eq("action", action)
    .maybeSingle();
  if (error) {
    console.error("dispatch lookup failed", error.message);
    return true;
  }
  return data != null;
}

async function markDispatched(
  supabase: ReturnType<typeof createClient>,
  scheduleId: string,
  userId: string,
  deviceId: string,
  action: LiveActivityFcmEvent,
): Promise<void> {
  await supabase.from("schedule_live_activity_dispatches").upsert({
    schedule_id: scheduleId,
    user_id: userId,
    device_id: deviceId,
    action,
    sent_at: new Date().toISOString(),
  }, { onConflict: "schedule_id,user_id,device_id,action" });
}

Deno.serve(async (req) => {
  try {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const cronSecret = Deno.env.get("SCHEDULE_LIVE_ACTIVITY_CRON_SECRET");
  const headerSecret = req.headers.get("x-cron-secret");
  if (!cronSecret || headerSecret !== cronSecret) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceAccountRaw || !supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Server misconfigured" }, 500);
  }

  let serviceAccount;
  try {
    serviceAccount = parseServiceAccountJson(serviceAccountRaw);
  } catch (e) {
    console.error("Firebase service account parse error", e);
    return jsonResponse({ error: "Server configuration error" }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const now = new Date();

  const nowIso = now.toISOString();
  const windowStart = new Date(now.getTime() - 90_000).toISOString();
  const windowEnd = new Date(now.getTime() + 60_000).toISOString();

  const { data: startingSchedules, error: scheduleError } = await supabase
    .from("event_schedules")
    .select("id, event_id, title, location, start_time, end_time, choir, voices")
    .gte("start_time", windowStart)
    .lte("start_time", windowEnd);

  if (scheduleError) {
    console.error("event_schedules query failed", scheduleError.message);
    return jsonResponse({ error: "Query failed", step: "starting_schedules", detail: scheduleError.message }, 500);
  }

  // ISO-Zeitstempel in Anführungszeichen — sonst bricht PostgREST .or() an den Doppelpunkten.
  const { data: activeSchedules, error: activeError } = await supabase
    .from("event_schedules")
    .select("id, event_id, title, location, start_time, end_time, choir, voices")
    .lte("start_time", nowIso)
    .or(`end_time.gte."${nowIso}",end_time.is.null`);

  if (activeError) {
    console.error("active schedules query failed", activeError.message);
    return jsonResponse({ error: "Query failed", step: "active_schedules", detail: activeError.message }, 500);
  }

  const eventIds = new Set<string>();
  for (const row of [...(startingSchedules ?? []), ...(activeSchedules ?? [])]) {
    eventIds.add(row.event_id);
  }

  if (eventIds.size === 0) {
    return jsonResponse({ processed: 0, sent: 0 });
  }

  const { data: events, error: eventsError } = await supabase
    .from("calendar_events")
    .select("id, event_name, choir, voices, type")
    .in("id", [...eventIds]);

  if (eventsError) {
    console.error("calendar_events query failed", eventsError.message);
    return jsonResponse({ error: "Query failed", step: "calendar_events", detail: eventsError.message }, 500);
  }

  const eventsById = new Map<string, CalendarEventRow>();
  for (const event of events ?? []) {
    eventsById.set(event.id, event as CalendarEventRow);
  }

  const { data: devices, error: devicesError } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, device_id, fcm_token, platform, schedule_filter, push_to_start_token, live_activity_push_token, profiles!inner(id, choir, voice)",
    )
    .not("fcm_token", "is", null);

  if (devicesError) {
    console.error("profile_push_devices query failed", devicesError.message);
    return jsonResponse({ error: "Query failed", step: "profile_push_devices", detail: devicesError.message }, 500);
  }

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const eventId of eventIds) {
    const event = eventsById.get(eventId);
    if (!event) continue;

    const { data: allSchedules, error: allError } = await supabase
      .from("event_schedules")
      .select("id, event_id, title, location, start_time, end_time, choir, voices")
      .eq("event_id", eventId)
      .order("start_time", { ascending: true });

    if (allError || !allSchedules?.length) continue;

    const activityId = `event_${eventId}`;

    for (const device of (devices ?? []) as DeviceRow[]) {
      const profile = asProfile(device.profiles);
      if (!profile || !profileMatchesEvent(profile, event)) {
        skipped++;
        continue;
      }

      const visibleSchedules = (allSchedules as ScheduleRow[]).filter((s) =>
        scheduleVisibleForProfile(s, profile, device.schedule_filter ?? "all")
      );
      if (visibleSchedules.length === 0) {
        skipped++;
        continue;
      }

      const snapshot = buildSnapshot(visibleSchedules, now);
      if (!snapshot) {
        skipped++;
        continue;
      }

      let fcmEvent: LiveActivityFcmEvent;
      if (snapshot.isFinished) {
        fcmEvent = "end";
      } else {
        const isStarting = (startingSchedules ?? []).some(
          (s) => s.id === snapshot.currentScheduleId,
        );
        fcmEvent = isStarting ? "start" : "update";
      }

      const dedupeScheduleId = snapshot.isFinished
        ? visibleSchedules[visibleSchedules.length - 1].id
        : snapshot.currentScheduleId;

      if (await wasDispatched(
        supabase,
        dedupeScheduleId,
        device.user_id,
        device.device_id,
        fcmEvent,
      )) {
        skipped++;
        continue;
      }

      const token = device.fcm_token?.trim();
      if (!token) {
        skipped++;
        continue;
      }

      const contentState = {
        currentTitle: snapshot.currentTitle,
        currentSubtitle: snapshot.currentSubtitle,
        hasNext: snapshot.hasNext,
        nextTitle: snapshot.nextTitle,
        nextSubtitle: snapshot.nextSubtitle,
        segmentStartMs: snapshot.segmentStartMs,
        segmentEndMs: snapshot.segmentEndMs,
        eventId,
      };

      const result = await sendLiveActivityFcm(serviceAccount, {
        token,
        platform: device.platform,
        event: fcmEvent,
        activityId,
        contentState,
        eventId,
        liveActivityPushToken: device.live_activity_push_token,
        pushToStartToken: device.push_to_start_token,
      });

      if (result.ok) {
        sent++;
        await markDispatched(
          supabase,
          dedupeScheduleId,
          device.user_id,
          device.device_id,
          fcmEvent,
        );
      } else {
        failed++;
        console.error(
          `LiveActivity FCM failed ${device.id}: ${result.errorCode}`,
        );
        if (isUnregisteredTokenError(result.errorCode)) {
          await supabase.from("profile_push_devices").delete().eq("id", device.id);
        }
      }
    }
  }

  return jsonResponse({
    processed: eventIds.size,
    sent,
    failed,
    skipped,
  });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("schedule-live-activity unhandled", e);
    return jsonResponse({ error: "Unhandled error", detail: message }, 500);
  }
});
