/**
 * Vereinheitlichte Live-Activity Edge Function (Event-Ablaufplan + Stundenplan).
 * Aufruf nur via pg_cron-Einmal-Jobs (mode=dispatch) oder DB-Trigger (mode=change).
 */

import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { parseServiceAccountJson } from "../_shared/fcm_v1.ts";
import type { LiveActivityFcmEvent } from "../_shared/fcm_v1.ts";
import {
  createDispatchSummary,
  logDispatchSummary,
  type DeviceDispatchDetail,
} from "../_shared/live_activity/dispatch_log.ts";
import {
  asProfile,
  groupDevicesByUser,
  loadEventDevices,
  loadTimetableDevicesBulk,
  profileMatchesEvent,
  resolveSegmentStartEvent,
} from "../_shared/live_activity/devices.ts";
import {
  sendLiveActivityBatch,
  type DispatchTarget,
} from "../_shared/live_activity/fcm_dispatch.ts";
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
import type { TimetableCalendarRow } from "../_shared/live_activity/series_occurrences.ts";
import {
  buildTimetableSnapshot,
  dayBoundsBerlin,
  emptyTimetableContentState,
  timetableSnapshotToContentState,
} from "../_shared/live_activity/timetable_snapshot.ts";
import type {
  CalendarEventRow,
  DeviceRow,
  LiveActivityKind,
  ProfileRow,
  RequestBody,
  ScheduleRow,
} from "../_shared/live_activity/types.ts";

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

/** reference_id kann "YYYY-MM-DD" oder legacy "YYYY-MM-DD|klasse|track" sein. */
function parseTimetableDayReference(referenceId: string): {
  dayDate: string;
  className?: string | null;
  schooltrack?: string | null;
} {
  const parts = referenceId.split("|");
  if (parts.length >= 3 && /^\d{4}-\d{2}-\d{2}$/.test(parts[0])) {
    return {
      dayDate: parts[0],
      className: parts[1] || null,
      schooltrack: parts[2] || null,
    };
  }
  return { dayDate: referenceId.slice(0, 10) };
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
  if (requested === "start") return "start";
  return resolveSegmentStartEvent(device);
}

function respondWithSummary(
  summary: ReturnType<typeof createDispatchSummary>,
): Response {
  logDispatchSummary(summary);
  return jsonResponse(summary);
}

async function buildTimetableTargets(
  supabase: ReturnType<typeof createClient>,
  devices: DeviceRow[],
  dayDate: string,
  action: LiveActivityFcmEvent,
  now: Date,
): Promise<{ targets: DispatchTarget[]; usersProcessed: number; skipped: DeviceDispatchDetail[] }> {
  const grouped = groupDevicesByUser(devices);
  const targets: DispatchTarget[] = [];
  const skipped: DeviceDispatchDetail[] = [];
  let usersProcessed = 0;

  const snapshotCache = new Map<
    string,
    Record<string, string | number | boolean> | null
  >();

  for (const [, userDevices] of grouped) {
    const profile = asProfile(userDevices[0]?.profiles);
    if (!profile) {
      for (const device of userDevices) {
        skipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_profile",
        });
      }
      continue;
    }

    usersProcessed++;

    const cacheKey = `${profile.class_name ?? ""}|${profile.schooltrack ?? ""}`;
    let resolvedContentState = snapshotCache.get(cacheKey);

    if (resolvedContentState === undefined) {
      if (action === "end") {
        resolvedContentState = emptyTimetableContentState(dayDate);
      } else {
        const rows = await loadMergedTimetableRows(supabase, dayDate, profile);
        const snapshot = buildTimetableSnapshot(dayDate, rows, profile, now);
        resolvedContentState = snapshot
          ? timetableSnapshotToContentState(snapshot)
          : null;
      }
      snapshotCache.set(cacheKey, resolvedContentState);
    }

    if (resolvedContentState === null) {
      for (const device of userDevices) {
        skipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_snapshot",
        });
      }
      continue;
    }

    for (const device of userDevices) {
      const fcmEvent = resolveFcmEvent(device, action);
      targets.push({
        device,
        fcmEvent,
        contentState: resolvedContentState,
        dedupKey: {
          day_date: dayDate,
          user_id: device.user_id,
          device_id: device.device_id,
        },
      });
    }
  }

  return { targets, usersProcessed, skipped };
}

async function handleEventDispatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const startedAt = Date.now();
  const eventId = request.reference_id!;
  const action = request.action;
  if (!action || (action !== "start" && action !== "update" && action !== "end")) {
    return jsonResponse({ error: "action (start|update|end) required" }, 400);
  }

  const event = await loadEvent(supabase, eventId);
  if (!event || !isEventType(event.type)) {
    const summary = createDispatchSummary({
      mode: "dispatch",
      kind: "event",
      reference_id: eventId,
      action,
      users_processed: 0,
      devices_total: 0,
      job_id: request.job_id ?? null,
    }, startedAt, []);
    return respondWithSummary(summary);
  }

  const schedules = await loadSchedules(supabase, eventId);
  const devices = await loadEventDevices(supabase, event);
  const scheduleId = request.schedule_id?.trim() || eventId;
  const targets: DispatchTarget[] = [];
  const preSkipped: DeviceDispatchDetail[] = [];

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      preSkipped.push({
        device_id: device.device_id,
        user_id: device.user_id,
        platform: device.platform,
        result: "skipped",
        skip_reason: "no_profile",
      });
      continue;
    }

    const filter = device.schedule_filter ?? "all";
    let contentState: Record<string, string | number | boolean>;

    if (schedules.length === 0) {
      const snapshot = buildEventOnlySnapshot(event);
      if (!snapshot) {
        preSkipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_snapshot",
        });
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    } else {
      const visible = visibleSchedulesToday(schedules, profile, filter, now);
      const snapshot = buildEventSnapshot(visible, now);
      if (!snapshot) {
        preSkipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_snapshot",
        });
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    }

    const fcmEvent = action === "start"
      ? resolveSegmentStartEvent(device)
      : action;

    targets.push({
      device,
      fcmEvent,
      contentState,
      dedupKey: {
        schedule_id: scheduleId,
        user_id: device.user_id,
        device_id: device.device_id,
      },
    });
  }

  const sendDetails = await sendLiveActivityBatch(supabase, serviceAccount, targets, {
    kind: "event",
    referenceId: eventId,
    activityType: "schedule_live_activity",
    dedupTable: "schedule_live_activity_dispatches",
    skipDedup: action === "update",
  });

  const summary = createDispatchSummary({
    mode: "dispatch",
    kind: "event",
    reference_id: eventId,
    action,
    users_processed: new Set(devices.map((d) => d.user_id)).size,
    devices_total: devices.length,
    job_id: request.job_id ?? null,
  }, startedAt, [...preSkipped, ...sendDetails]);

  return respondWithSummary(summary);
}

async function handleTimetableDispatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const startedAt = Date.now();
  const parsed = parseTimetableDayReference(request.reference_id!);
  const dayDate = parsed.dayDate;
  const action = request.action;

  if (!action || (action !== "start" && action !== "update" && action !== "end")) {
    return jsonResponse({ error: "action (start|update|end) required" }, 400);
  }

  const className = request.class_name ?? parsed.className;
  const schooltrack = request.schooltrack ?? parsed.schooltrack;

  const devices = await loadTimetableDevicesBulk(supabase, {
    userId: request.user_id,
    className: request.user_id ? undefined : className,
    schooltrack: request.user_id ? undefined : schooltrack,
  });

  if (devices.length === 0) {
    const summary = createDispatchSummary({
      mode: "dispatch",
      kind: "timetable",
      reference_id: dayDate,
      action,
      user_id: request.user_id ?? null,
      class_name: className ?? null,
      schooltrack: schooltrack ?? null,
      users_processed: 0,
      devices_total: 0,
      job_id: request.job_id ?? null,
    }, startedAt, []);
    return respondWithSummary(summary);
  }

  const { targets, usersProcessed, skipped } = await buildTimetableTargets(
    supabase,
    devices,
    dayDate,
    action,
    now,
  );

  const sendDetails = await sendLiveActivityBatch(supabase, serviceAccount, targets, {
    kind: "timetable",
    referenceId: dayDate,
    activityType: "timetable_live_activity",
    dayDate,
    dedupTable: "timetable_live_activity_dispatches",
    skipDedup: action === "update",
  });

  const summary = createDispatchSummary({
    mode: "dispatch",
    kind: "timetable",
    reference_id: dayDate,
    action,
    user_id: request.user_id ?? null,
    class_name: className ?? null,
    schooltrack: schooltrack ?? null,
    users_processed: usersProcessed,
    devices_total: devices.length,
    job_id: request.job_id ?? null,
  }, startedAt, [...skipped, ...sendDetails]);

  return respondWithSummary(summary);
}

async function handleEventChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const startedAt = Date.now();
  const eventId = request.reference_id!;
  const event = await loadEvent(
    supabase,
    eventId,
    request.op === "DELETE" ? request.event_snapshot : null,
  );

  if (event && !isEventType(event.type)) {
    const summary = createDispatchSummary({
      mode: "change",
      kind: "event",
      reference_id: eventId,
      users_processed: 0,
      devices_total: 0,
    }, startedAt, []);
    return respondWithSummary(summary);
  }

  const schedules = await loadSchedules(supabase, eventId);
  const isDeleted = request.op === "DELETE" || event == null;

  if (!isDeleted && event && !isEventRelevantToday(event, schedules, now)) {
    const summary = createDispatchSummary({
      mode: "change",
      kind: "event",
      reference_id: eventId,
      users_processed: 0,
      devices_total: 0,
    }, startedAt, []);
    return respondWithSummary(summary);
  }

  const referenceEvent = event ?? request.event_snapshot;
  if (!referenceEvent) {
    const summary = createDispatchSummary({
      mode: "change",
      kind: "event",
      reference_id: eventId,
      users_processed: 0,
      devices_total: 0,
    }, startedAt, []);
    return respondWithSummary(summary);
  }

  const devices = await loadEventDevices(supabase, referenceEvent as CalendarEventRow);
  const targets: DispatchTarget[] = [];
  const preSkipped: DeviceDispatchDetail[] = [];

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      preSkipped.push({
        device_id: device.device_id,
        user_id: device.user_id,
        platform: device.platform,
        result: "skipped",
        skip_reason: "no_profile",
      });
      continue;
    }

    if (isDeleted || !event || !profileMatchesEvent(profile, referenceEvent as CalendarEventRow)) {
      targets.push({
        device,
        fcmEvent: "end",
        contentState: emptyEventContentState(eventId),
        dedupKey: {
          schedule_id: schedules.at(-1)?.id ?? eventId,
          user_id: device.user_id,
          device_id: device.device_id,
        },
      });
      continue;
    }

    const filter = device.schedule_filter ?? "all";
    let contentState: Record<string, string | number | boolean>;

    if (schedules.length === 0) {
      const snapshot = buildEventOnlySnapshot(event);
      if (!snapshot || !isEventActiveToday(event, now)) {
        preSkipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_snapshot",
        });
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    } else {
      const visible = visibleSchedulesToday(schedules, profile, filter, now);
      const snapshot = buildEventSnapshot(visible, now);
      if (!snapshot) {
        preSkipped.push({
          device_id: device.device_id,
          user_id: device.user_id,
          platform: device.platform,
          result: "skipped",
          skip_reason: "no_snapshot",
        });
        continue;
      }
      contentState = snapshotToContentState(snapshot, eventId);
    }

    const fcmEvent = resolveSegmentStartEvent(device);
    targets.push({
      device,
      fcmEvent: fcmEvent === "start" ? "update" : fcmEvent,
      contentState,
      dedupKey: {
        schedule_id: schedules.length > 0
          ? (buildEventSnapshot(visibleSchedulesToday(schedules, profile, filter, now), now)
            ?.currentScheduleId ?? eventId)
          : eventId,
        user_id: device.user_id,
        device_id: device.device_id,
      },
    });
  }

  const sendDetails = await sendLiveActivityBatch(supabase, serviceAccount, targets, {
    kind: "event",
    referenceId: eventId,
    activityType: "schedule_live_activity",
    dedupTable: "schedule_live_activity_dispatches",
    skipDedup: true,
  });

  const summary = createDispatchSummary({
    mode: "change",
    kind: "event",
    reference_id: eventId,
    users_processed: new Set(devices.map((d) => d.user_id)).size,
    devices_total: devices.length,
  }, startedAt, [...preSkipped, ...sendDetails]);

  return respondWithSummary(summary);
}

async function handleTimetableChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const startedAt = Date.now();
  const dayDate = request.reference_id ?? new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Berlin",
  }).format(now);

  const devices = await loadTimetableDevicesBulk(supabase, {});
  const { targets, usersProcessed, skipped } = await buildTimetableTargets(
    supabase,
    devices,
    dayDate,
    "update",
    now,
  );

  // Change-Events nutzen update/start je nach Gerätestatus.
  const adjustedTargets = targets.map((target) => {
    const fcmEvent = resolveSegmentStartEvent(target.device);
    return {
      ...target,
      fcmEvent: fcmEvent === "start" ? "update" : fcmEvent,
    };
  });

  const sendDetails = await sendLiveActivityBatch(
    supabase,
    serviceAccount,
    adjustedTargets,
    {
      kind: "timetable",
      referenceId: dayDate,
      activityType: "timetable_live_activity",
      dayDate,
      dedupTable: "timetable_live_activity_dispatches",
      skipDedup: true,
    },
  );

  const summary = createDispatchSummary({
    mode: "change",
    kind: "timetable",
    reference_id: dayDate,
    users_processed: usersProcessed,
    devices_total: devices.length,
  }, startedAt, [...skipped, ...sendDetails]);

  return respondWithSummary(summary);
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
    console.error(JSON.stringify({
      tag: "live_activity_dispatch",
      error: "unhandled",
      detail: message,
    }));
    return jsonResponse({ error: "Unhandled error", detail: message }, 500);
  }
});
