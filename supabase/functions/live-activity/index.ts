/**
 * Vereinheitlichte Live-Activity Edge Function (Event-Ablaufplan + Stundenplan).
 * Aufruf nur via pg_cron-Einmal-Jobs (mode=dispatch) oder DB-Trigger (mode=change).
 */

import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { parseServiceAccountJson } from "../_shared/fcm_v1.ts";
import type { LiveActivityFcmEvent } from "../_shared/fcm_v1.ts";
import { asProfile, loadEventDevices, loadTimetableDevices, profileMatchesEvent, resolveSegmentStartEvent } from "../_shared/live_activity/devices.ts";
import {
  buildEventOnlySnapshot,
  buildEventSnapshot,
  emptyEventContentState,
  isEventActiveToday,
  isEventRelevantToday,
  isEventType,
  snapshotToContentState,
  visibleSchedulesToday,
} from "../_shared/live_activity/event_snapshot.ts";
import { sendLiveActivityToDevice } from "../_shared/live_activity/fcm_dispatch.ts";
import type { TimetableCalendarRow } from "../_shared/live_activity/series_occurrences.ts";
import {
  buildTimetableSnapshot,
  dayBoundsBerlin,
  emptyTimetableContentState,
  timetableSnapshotToContentState,
} from "../_shared/live_activity/timetable_snapshot.ts";
import type { CalendarEventRow, LiveActivityKind, ProfileRow, RequestBody, ScheduleRow } from "../_shared/live_activity/types.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeRequest(raw: RequestBody): RequestBody {
  const kind = raw.kind ??
    (raw.event_id && !raw.reference_id ? "event" : raw.user_id ? "timetable" : "event");
  const referenceId = raw.reference_id ?? raw.event_id ?? raw.day_date;
  return {
    ...raw,
    kind: kind as LiveActivityKind,
    reference_id: referenceId,
  };
}

async function loadEvent(
  supabase: ReturnType<typeof createClient>,
  eventId: string,
  snapshot?: CalendarEventRow | null,
): Promise<CalendarEventRow | null> {
  if (snapshot?.id) return snapshot;

  const { data, error } = await supabase
    .from("calendar_events")
    .select("id, event_name, start_time, end_time, location, choir, voices, type")
    .eq("id", eventId)
    .maybeSingle();

  if (error) throw new Error(error.message);
  return data as CalendarEventRow | null;
}

async function loadSchedules(
  supabase: ReturnType<typeof createClient>,
  eventId: string,
): Promise<ScheduleRow[]> {
  const { data, error } = await supabase
    .from("event_schedules")
    .select("id, event_id, title, location, start_time, end_time, choir, voices")
    .eq("event_id", eventId)
    .order("start_time", { ascending: true });

  if (error) throw new Error(error.message);
  return (data ?? []) as ScheduleRow[];
}

async function loadProfile(
  supabase: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, choir, voice, class_name, schooltrack")
    .eq("id", userId)
    .maybeSingle();

  if (error) throw new Error(error.message);
  return data;
}

async function loadMergedTimetableRows(
  supabase: ReturnType<typeof createClient>,
  dayDate: string,
  profile: ProfileRow,
): Promise<TimetableCalendarRow[]> {
  const bounds = dayBoundsBerlin(dayDate);
  const dayDateOnly = dayDate.slice(0, 10);

  const [{ data: events, error: eventsError }, { data: series, error: seriesError }] =
    await Promise.all([
      supabase
        .from("calendar_events")
        .select(
          "id, event_name, type, start_time, end_time, class, schooltrack, image_paths, series_id, recurrence_id",
        )
        .in("type", ["lesson", "meal"])
        .gte("start_time", bounds.start)
        .lte("start_time", bounds.end),
      supabase
        .from("calendar_series")
        .select(
          "id, event_name, type, rrule, series_start, series_end, start_time, end_time, class, schooltrack",
        )
        .in("type", ["lesson", "meal"])
        .lte("series_start", dayDateOnly)
        .or(`series_end.is.null,series_end.gte.${dayDateOnly}`),
    ]);

  if (eventsError) throw new Error(eventsError.message);
  if (seriesError) throw new Error(seriesError.message);

  const { mergeTimetableRowsForDay } = await import(
    "../_shared/live_activity/series_occurrences.ts"
  );

  return await mergeTimetableRowsForDay(
    dayDateOnly,
    events ?? [],
    series ?? [],
    profile,
  );
}

function resolveFcmEvent(
  device: { live_activity_push_token: string | null },
  requested: LiveActivityFcmEvent | undefined,
): LiveActivityFcmEvent {
  if (requested === "end") return "end";
  if (requested === "update") return "update";
  return resolveSegmentStartEvent(device);
}

async function handleEventDispatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const eventId = request.reference_id!;
  const action = request.action;
  if (!action || (action !== "start" && action !== "update" && action !== "end")) {
    return jsonResponse({ error: "action (start|update|end) required" }, 400);
  }

  const event = await loadEvent(supabase, eventId);
  if (!event || !isEventType(event.type)) {
    return jsonResponse({ processed: 0, sent: 0, skipped: 0, mode: "dispatch", kind: "event" });
  }

  const schedules = await loadSchedules(supabase, eventId);
  const devices = await loadEventDevices(supabase, event);
  const scheduleId = request.schedule_id?.trim() || eventId;

  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      skipped++;
      continue;
    }

    const filter = device.schedule_filter ?? "all";
    let contentState: Record<string, string | number | boolean>;

    if (schedules.length === 0) {
      const snapshot = buildEventOnlySnapshot(event);
      if (!snapshot) {
        skipped++;
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    } else {
      const visible = visibleSchedulesToday(schedules, profile, filter, now);
      const snapshot = buildEventSnapshot(visible, now);
      if (!snapshot) {
        skipped++;
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    }

    const fcmEvent = action === "start"
      ? resolveSegmentStartEvent(device)
      : action;

    const result = await sendLiveActivityToDevice(supabase, serviceAccount, device, {
      kind: "event",
      referenceId: eventId,
      fcmEvent,
      contentState,
      activityType: "schedule_live_activity",
      dedupTable: "schedule_live_activity_dispatches",
      dedupKey: {
        schedule_id: scheduleId,
        user_id: device.user_id,
        device_id: device.device_id,
      },
      skipDedup: fcmEvent === "update",
    });

    if (result === "sent") sent++;
    else if (result === "failed") failed++;
    else skipped++;
  }

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "dispatch",
    kind: "event",
    reference_id: eventId,
    action,
    job_id: request.job_id ?? null,
  });
}

async function handleTimetableDispatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const dayDate = request.reference_id!;
  const userId = request.user_id;
  const action = request.action;

  if (!userId) {
    return jsonResponse({ error: "user_id required for timetable dispatch" }, 400);
  }
  if (!action || (action !== "start" && action !== "update" && action !== "end")) {
    return jsonResponse({ error: "action (start|update|end) required" }, 400);
  }

  const profile = await loadProfile(supabase, userId);
  if (!profile) {
    return jsonResponse({ processed: 0, sent: 0, skipped: 0, mode: "dispatch", kind: "timetable" });
  }

  const rows = await loadMergedTimetableRows(supabase, dayDate, profile);
  const snapshot = action === "end"
    ? null
    : buildTimetableSnapshot(dayDate, rows, profile, now);

  const contentState = snapshot
    ? timetableSnapshotToContentState(snapshot)
    : emptyTimetableContentState(dayDate);

  const devices = await loadTimetableDevices(supabase, userId);
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const device of devices) {
    const fcmEvent = resolveFcmEvent(device, action);
    const result = await sendLiveActivityToDevice(supabase, serviceAccount, device, {
      kind: "timetable",
      referenceId: dayDate,
      fcmEvent,
      contentState,
      activityType: "timetable_live_activity",
      dayDate,
      dedupTable: "timetable_live_activity_dispatches",
      dedupKey: {
        day_date: dayDate,
        user_id: device.user_id,
        device_id: device.device_id,
      },
      skipDedup: fcmEvent === "update",
    });

    if (result === "sent") sent++;
    else if (result === "failed") failed++;
    else skipped++;
  }

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "dispatch",
    kind: "timetable",
    reference_id: dayDate,
    user_id: userId,
    action,
    job_id: request.job_id ?? null,
  });
}

async function handleEventChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const eventId = request.reference_id!;
  const event = await loadEvent(
    supabase,
    eventId,
    request.op === "DELETE" ? request.event_snapshot : null,
  );

  if (event && !isEventType(event.type)) {
    return jsonResponse({ processed: 0, sent: 0, skipped: 0, mode: "change", kind: "event" });
  }

  const schedules = await loadSchedules(supabase, eventId);
  const isDeleted = request.op === "DELETE" || event == null;

  if (!isDeleted && event && !isEventRelevantToday(event, schedules, now)) {
    return jsonResponse({ processed: 1, sent: 0, skipped: 0, mode: "change", kind: "event" });
  }

  const referenceEvent = event ?? request.event_snapshot;
  if (!referenceEvent) {
    return jsonResponse({ processed: 1, sent: 0, skipped: 0, mode: "change", kind: "event" });
  }

  const devices = await loadEventDevices(supabase, referenceEvent as CalendarEventRow);
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      skipped++;
      continue;
    }

    if (isDeleted || !event || !profileMatchesEvent(profile, referenceEvent as CalendarEventRow)) {
      const result = await sendLiveActivityToDevice(supabase, serviceAccount, device, {
        kind: "event",
        referenceId: eventId,
        fcmEvent: "end",
        contentState: emptyEventContentState(eventId),
        activityType: "schedule_live_activity",
        dedupTable: "schedule_live_activity_dispatches",
        dedupKey: {
          schedule_id: schedules.at(-1)?.id ?? eventId,
          user_id: device.user_id,
          device_id: device.device_id,
        },
        skipDedup: true,
      });
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
      continue;
    }

    const filter = device.schedule_filter ?? "all";
    let contentState: Record<string, string | number | boolean>;

    if (schedules.length === 0) {
      const snapshot = buildEventOnlySnapshot(event);
      if (!snapshot || !isEventActiveToday(event, now)) {
        skipped++;
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    } else {
      const visible = visibleSchedulesToday(schedules, profile, filter, now);
      const snapshot = buildEventSnapshot(visible, now);
      if (!snapshot) {
        skipped++;
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    }

    const fcmEvent = resolveSegmentStartEvent(device);
    const result = await sendLiveActivityToDevice(supabase, serviceAccount, device, {
      kind: "event",
      referenceId: eventId,
      fcmEvent: fcmEvent === "start" ? "update" : fcmEvent,
      contentState,
      activityType: "schedule_live_activity",
      dedupTable: "schedule_live_activity_dispatches",
      dedupKey: {
        schedule_id: schedules.length > 0
          ? (buildEventSnapshot(visibleSchedulesToday(schedules, profile, filter, now), now)
            ?.currentScheduleId ?? eventId)
          : eventId,
        user_id: device.user_id,
        device_id: device.device_id,
      },
      skipDedup: true,
    });

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
    kind: "event",
    reference_id: eventId,
  });
}

async function handleTimetableChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const dayDate = request.reference_id ?? new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Berlin",
  }).format(now);

  const { data: userRows, error: userRowsError } = await supabase
    .from("profile_push_devices")
    .select("user_id")
    .not("fcm_token", "is", null);

  if (userRowsError) throw new Error(userRowsError.message);

  const userIds = [...new Set((userRows ?? []).map((r) => r.user_id as string))];

  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const userId of userIds) {
    const profile = await loadProfile(supabase, userId);
    if (!profile) continue;

    const rows = await loadMergedTimetableRows(supabase, dayDate, profile as ProfileRow);
    const snapshot = buildTimetableSnapshot(dayDate, rows, profile as ProfileRow, now);
    if (!snapshot) continue;

    const devices = await loadTimetableDevices(supabase, userId);
    for (const device of devices) {
      const fcmEvent = resolveSegmentStartEvent(device);
      const result = await sendLiveActivityToDevice(supabase, serviceAccount, device, {
        kind: "timetable",
        referenceId: dayDate,
        fcmEvent: fcmEvent === "start" ? "update" : fcmEvent,
        contentState: timetableSnapshotToContentState(snapshot),
        activityType: "timetable_live_activity",
        dayDate,
        dedupTable: "timetable_live_activity_dispatches",
        dedupKey: {
          day_date: dayDate,
          user_id: device.user_id,
          device_id: device.device_id,
        },
        skipDedup: true,
      });

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
    mode: "change",
    kind: "timetable",
    reference_id: dayDate,
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

    let body: RequestBody = {};
    try {
      const rawBody = await req.text();
      if (rawBody.trim().length === 0) {
        return jsonResponse({ error: "Request body required" }, 400);
      }
      body = normalizeRequest(JSON.parse(rawBody) as RequestBody);
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const kind = body.kind ?? "event";
    const referenceId = body.reference_id;

    if (body.mode === "dispatch") {
      if (!referenceId) {
        return jsonResponse({ error: "reference_id required" }, 400);
      }
      if (kind === "timetable") {
        return await handleTimetableDispatch(supabase, serviceAccount, body, now);
      }
      return await handleEventDispatch(supabase, serviceAccount, body, now);
    }

    if (body.mode === "change") {
      if (kind === "timetable") {
        return await handleTimetableChange(supabase, serviceAccount, body, now);
      }
      if (!referenceId) {
        return jsonResponse({ error: "reference_id required" }, 400);
      }
      return await handleEventChange(supabase, serviceAccount, body, now);
    }

    return jsonResponse({ error: "Invalid mode" }, 400);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("live-activity unhandled", e);
    return jsonResponse({ error: "Unhandled error", detail: message }, 500);
  }
});
