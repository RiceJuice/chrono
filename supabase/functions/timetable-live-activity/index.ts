/**
 * Stundenplan-Live-Activity: Push-to-Start 15 min vor erster Stunde, Ende nach letztem Segment.
 * Vollständiger Tagesplan liegt im Payload; Segmentwechsel laufen nativ auf dem Gerät.
 *
 * Cron: alle 15 Minuten (kein minütliches Polling).
 * Change: DB-Trigger bei lesson/meal-Änderungen.
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

const SCHEDULE_TIMEZONE = "Europe/Berlin";
const PRE_START_MINUTES = 15;
const WINDOW_MS = 120_000;

type DeviceRow = {
  id: string;
  user_id: string;
  device_id: string;
  fcm_token: string;
  platform: string;
  push_to_start_token: string | null;
  live_activity_push_token: string | null;
};

type CalendarRow = {
  id: string;
  event_name: string | null;
  type: string | null;
  start_time: string;
  end_time: string | null;
  class: string | null;
  diet: string | null;
  image_paths: string | null;
};

type SeriesRow = {
  id: string;
  event_name: string | null;
  type: string | null;
  start_time: string;
  end_time: string | null;
  class: string | null;
  diet: string | null;
  series_start: string;
  series_end: string | null;
  subject_id: string | null;
};

type SubjectRow = {
  id: string;
  default_color: string | null;
};

type ChangeRequest = {
  mode?: string;
  source?: string;
  op?: string;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function localDateKey(d: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: SCHEDULE_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

function dayBoundsUtc(dayKey: string): { start: string; end: string } {
  return {
    start: `${dayKey}T00:00:00+02:00`,
    end: `${dayKey}T23:59:59+02:00`,
  };
}

function effectiveEnd(row: { start_time: string; end_time: string | null }): Date {
  return new Date(row.end_time ?? row.start_time);
}

async function loadDevices(
  supabase: ReturnType<typeof createClient>,
): Promise<DeviceRow[]> {
  const { data, error } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, device_id, fcm_token, platform, push_to_start_token, live_activity_push_token",
    )
    .not("fcm_token", "is", null);

  if (error) throw new Error(error.message);
  return (data ?? []) as DeviceRow[];
}

async function wasDispatched(
  supabase: ReturnType<typeof createClient>,
  dayDate: string,
  userId: string,
  deviceId: string,
  action: LiveActivityFcmEvent,
): Promise<boolean> {
  const { data } = await supabase
    .from("timetable_live_activity_dispatches")
    .select("id")
    .eq("day_date", dayDate)
    .eq("user_id", userId)
    .eq("device_id", deviceId)
    .eq("action", action)
    .maybeSingle();
  return data != null;
}

async function markDispatched(
  supabase: ReturnType<typeof createClient>,
  dayDate: string,
  userId: string,
  deviceId: string,
  action: LiveActivityFcmEvent,
): Promise<void> {
  await supabase.from("timetable_live_activity_dispatches").upsert({
    day_date: dayDate,
    user_id: userId,
    device_id: deviceId,
    action,
    sent_at: new Date().toISOString(),
  }, { onConflict: "day_date,user_id,device_id,action" });
}

function minimalContentState(dayDate: string): Record<string, string | number | boolean> {
  return {
    kind: "timetable",
    dayDate,
    segmentsJson: "[]",
    activityStartMs: 0,
    dayEndMs: 0,
    remainingLessons: 0,
    currentIndex: 0,
    currentTitle: "Stundenplan",
    currentSubtitle: "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: 0,
    segmentEndMs: 0,
    accentColor: "#124E30",
    isMeal: false,
    imageUrl: "",
    eventId: dayDate,
    isPreStart: false,
  };
}

function resolveSegmentStartEvent(device: DeviceRow): LiveActivityFcmEvent {
  const liveToken = device.live_activity_push_token?.trim();
  return liveToken && liveToken.length > 0 ? "update" : "start";
}

async function sendForDevice(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  device: DeviceRow,
  dayDate: string,
  fcmEvent: LiveActivityFcmEvent,
  options?: { skipDedup?: boolean },
): Promise<"sent" | "skipped" | "failed"> {
  if (
    !options?.skipDedup &&
    await wasDispatched(supabase, dayDate, device.user_id, device.device_id, fcmEvent)
  ) {
    return "skipped";
  }

  const token = device.fcm_token?.trim();
  if (!token) return "skipped";

  const activityId = `timetable_${dayDate}`;
  const contentState = minimalContentState(dayDate);
  const result = await sendLiveActivityFcm(serviceAccount, {
    token,
    platform: device.platform,
    event: fcmEvent,
    activityId,
    contentState,
    eventId: dayDate,
    dayDate,
    activityType: "timetable_live_activity",
    liveActivityPushToken: device.live_activity_push_token,
    pushToStartToken: device.push_to_start_token,
  });

  if (result.ok) {
    if (!options?.skipDedup) {
      await markDispatched(
        supabase,
        dayDate,
        device.user_id,
        device.device_id,
        fcmEvent,
      );
    }
    return "sent";
  }

  if (isUnregisteredTokenError(result.errorCode)) {
    await supabase.from("profile_push_devices").delete().eq("id", device.id);
  }
  return "failed";
}

async function loadTodaySchoolRows(
  supabase: ReturnType<typeof createClient>,
  dayKey: string,
): Promise<CalendarRow[]> {
  const bounds = dayBoundsUtc(dayKey);
  const { data: events } = await supabase
    .from("calendar_events")
    .select("id, event_name, type, start_time, end_time, class, diet, image_paths")
    .in("type", ["lesson", "meal"])
    .gte("start_time", bounds.start)
    .lte("start_time", bounds.end)
    .order("start_time", { ascending: true });

  return (events ?? []) as CalendarRow[];
}

async function handleCronTick(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  now: Date,
): Promise<Response> {
  const dayKey = localDateKey(now);
  const rows = await loadTodaySchoolRows(supabase, dayKey);
  const lessons = rows.filter((r) => r.type === "lesson");
  if (lessons.length === 0) {
    return jsonResponse({ processed: 0, sent: 0, mode: "cron" });
  }

  const firstLessonStart = new Date(lessons[0].start_time);
  const activityStart = new Date(
    firstLessonStart.getTime() - PRE_START_MINUTES * 60_000,
  );

  const relevant = rows.filter((r) => r.type === "lesson" || r.type === "meal");
  const lastEnd = relevant.reduce((max, row) => {
    const end = effectiveEnd(row);
    return end > max ? end : max;
  }, effectiveEnd(relevant[0]));

  const nowMs = now.getTime();
  const shouldStart = Math.abs(nowMs - activityStart.getTime()) <= WINDOW_MS;
  const shouldEnd = Math.abs(nowMs - lastEnd.getTime()) <= WINDOW_MS;

  if (!shouldStart && !shouldEnd) {
    return jsonResponse({ processed: 0, sent: 0, mode: "cron" });
  }

  let devices: DeviceRow[];
  try {
    devices = await loadDevices(supabase);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const device of devices) {
    if (shouldStart) {
      const fcmEvent = resolveSegmentStartEvent(device);
      const result = await sendForDevice(
        supabase,
        serviceAccount,
        device,
        dayKey,
        fcmEvent,
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
    }

    if (shouldEnd) {
      const result = await sendForDevice(
        supabase,
        serviceAccount,
        device,
        dayKey,
        "end",
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
    }
  }

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "cron",
    day_date: dayKey,
    should_start: shouldStart,
    should_end: shouldEnd,
  });
}

async function handleContentChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  now: Date,
): Promise<Response> {
  const dayKey = localDateKey(now);
  const rows = await loadTodaySchoolRows(supabase, dayKey);
  if (rows.length === 0) {
    return jsonResponse({ processed: 1, sent: 0, skipped: 0, mode: "change" });
  }

  let devices: DeviceRow[];
  try {
    devices = await loadDevices(supabase);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const device of devices) {
    const alreadyStarted = await wasDispatched(
      supabase,
      dayKey,
      device.user_id,
      device.device_id,
      "start",
    );
    const fcmEvent: LiveActivityFcmEvent = alreadyStarted
      ? "update"
      : resolveSegmentStartEvent(device);

    const result = await sendForDevice(
      supabase,
      serviceAccount,
      device,
      dayKey,
      fcmEvent,
      fcmEvent === "update" ? { skipDedup: true } : undefined,
    );
    if (result === "sent") sent++;
    else if (result === "failed") failed++;
    else skipped++;
  }

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "change",
    day_date: dayKey,
  });
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

    const serviceAccount = parseServiceAccountJson(serviceAccountRaw);
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const now = new Date();

    let changeRequest: ChangeRequest = {};
    try {
      const rawBody = await req.text();
      if (rawBody.trim().length > 0) {
        changeRequest = JSON.parse(rawBody) as ChangeRequest;
      }
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    if (changeRequest.mode === "change") {
      return await handleContentChange(supabase, serviceAccount, now);
    }

    return await handleCronTick(supabase, serviceAccount, now);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("timetable-live-activity unhandled", e);
    return jsonResponse({ error: "Unhandled error", detail: message }, 500);
  }
});
