/**
 * Bedarfsgesteuerte FCM Live Activities für Kalender-Events (type = event).
 * DB-Trigger + geplante pg_cron-Einmal-Jobs → start/end an Termin-/Segmentgrenzen.
 * DB-Trigger bei Änderungen → FCM update/end bei laufender Live Activity.
 *
 * Countdown läuft nativ auf dem Gerät (iOS TimelineView / Android Chronometer).
 * Server sendet nur: start (Push-to-Start), update (Inhaltsänderung), end.
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
  start_time?: string | null;
  end_time?: string | null;
  location?: string | null;
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
};

type RequestBody = {
  mode?: string;
  event_id?: string;
  schedule_id?: string | null;
  action?: string;
  job_id?: string;
  op?: string;
  source?: string;
  event_snapshot?: CalendarEventRow;
};

type SendOptions = {
  skipDedup?: boolean;
  dedupAction?: LiveActivityFcmEvent;
  dispatchCache?: DispatchCache;
};

function isEventType(raw: string | null | undefined): boolean {
  return (raw ?? "").trim().toLowerCase() === "event";
}

function dispatchKey(
  scheduleId: string,
  userId: string,
  deviceId: string,
  action: LiveActivityFcmEvent,
): string {
  return `${scheduleId}:${userId}:${deviceId}:${action}`;
}

class DispatchCache {
  private readonly dispatched = new Set<string>();
  private readonly pendingUpserts: Array<{
    schedule_id: string;
    user_id: string;
    device_id: string;
    action: LiveActivityFcmEvent;
    sent_at: string;
  }> = [];

  wasDispatched(
    scheduleId: string,
    userId: string,
    deviceId: string,
    action: LiveActivityFcmEvent,
  ): boolean {
    return this.dispatched.has(dispatchKey(scheduleId, userId, deviceId, action));
  }

  markDispatched(
    scheduleId: string,
    userId: string,
    deviceId: string,
    action: LiveActivityFcmEvent,
  ): void {
    const key = dispatchKey(scheduleId, userId, deviceId, action);
    if (this.dispatched.has(key)) return;
    this.dispatched.add(key);
    this.pendingUpserts.push({
      schedule_id: scheduleId,
      user_id: userId,
      device_id: deviceId,
      action,
      sent_at: new Date().toISOString(),
    });
  }

  static async load(
    supabase: ReturnType<typeof createClient>,
    scheduleIds: string[],
    actions: LiveActivityFcmEvent[],
  ): Promise<DispatchCache> {
    const cache = new DispatchCache();
    if (scheduleIds.length === 0 || actions.length === 0) return cache;

    const { data, error } = await supabase
      .from("schedule_live_activity_dispatches")
      .select("schedule_id, user_id, device_id, action")
      .in("schedule_id", scheduleIds)
      .in("action", actions);

    if (error) {
      console.error("dispatch batch lookup failed", error.message);
      return cache;
    }

    for (const row of data ?? []) {
      cache.dispatched.add(
        dispatchKey(row.schedule_id, row.user_id, row.device_id, row.action),
      );
    }
    return cache;
  }

  async flush(supabase: ReturnType<typeof createClient>): Promise<void> {
    const chunkSize = 100;
    for (let i = 0; i < this.pendingUpserts.length; i += chunkSize) {
      const chunk = this.pendingUpserts.slice(i, i + chunkSize);
      const { error } = await supabase
        .from("schedule_live_activity_dispatches")
        .upsert(chunk, {
          onConflict: "schedule_id,user_id,device_id,action",
        });
      if (error) {
        console.error("dispatch batch upsert failed", error.message);
      }
    }
  }
}

function resolveSegmentStartEvent(device: DeviceRow): LiveActivityFcmEvent {
  const liveToken = device.live_activity_push_token?.trim();
  return liveToken && liveToken.length > 0 ? "update" : "start";
}

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

const SCHEDULE_TIMEZONE = "Europe/Berlin";

function localDateKey(d: Date): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: SCHEDULE_TIMEZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

function isSameLocalDay(a: Date, b: Date): boolean {
  return localDateKey(a) === localDateKey(b);
}

function visibleSchedulesToday(
  schedules: ScheduleRow[],
  profile: ProfileRow,
  filter: string,
  now: Date,
): ScheduleRow[] {
  return schedules
    .filter((s) =>
      isSameLocalDay(new Date(s.start_time), now) &&
      scheduleVisibleForProfile(s, profile, filter)
    )
    .sort((a, b) =>
      new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
    );
}

function hasSchedulesToday(schedules: ScheduleRow[], now: Date): boolean {
  return schedules.some((s) => isSameLocalDay(new Date(s.start_time), now));
}

function isEventActiveToday(event: CalendarEventRow, now: Date): boolean {
  if (!event.start_time || !event.end_time) return false;
  const start = new Date(event.start_time);
  const end = new Date(event.end_time);
  return isSameLocalDay(start, now) && start <= now && end > now;
}

function isEventRelevantToday(
  event: CalendarEventRow,
  schedules: ScheduleRow[],
  now: Date,
): boolean {
  if (schedules.length > 0) {
    return hasSchedulesToday(schedules, now);
  }
  if (!event.start_time || !event.end_time) return false;
  return isSameLocalDay(new Date(event.start_time), now);
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
  };
}

function buildEventOnlySnapshot(
  event: CalendarEventRow,
): Snapshot | null {
  if (!event.start_time || !event.end_time) return null;
  return {
    currentScheduleId: event.id,
    currentTitle: event.event_name ?? "",
    currentSubtitle: event.location ?? "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: new Date(event.start_time).getTime(),
    segmentEndMs: new Date(event.end_time).getTime(),
  };
}

function snapshotToContentState(
  snapshot: Snapshot,
  eventId: string,
): Record<string, string | number | boolean> {
  return {
    currentTitle: snapshot.currentTitle,
    currentSubtitle: snapshot.currentSubtitle,
    hasNext: snapshot.hasNext,
    nextTitle: snapshot.nextTitle,
    nextSubtitle: snapshot.nextSubtitle,
    segmentStartMs: snapshot.segmentStartMs,
    segmentEndMs: snapshot.segmentEndMs,
    eventId,
  };
}

function emptyContentState(eventId: string): Record<string, string | number | boolean> {
  return {
    currentTitle: "",
    currentSubtitle: "",
    hasNext: false,
    nextTitle: "",
    nextSubtitle: "",
    segmentStartMs: 0,
    segmentEndMs: 0,
    eventId,
  };
}

function isLastVisibleSegmentOfDay(
  schedule: ScheduleRow,
  visibleToday: ScheduleRow[],
): boolean {
  if (visibleToday.length === 0) return false;
  return visibleToday[visibleToday.length - 1].id === schedule.id;
}

function dedupScheduleId(
  eventId: string,
  scheduleId: string | null | undefined,
): string {
  return scheduleId?.trim() ? scheduleId : eventId;
}

async function sendForDevice(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  device: DeviceRow,
  eventId: string,
  scheduleId: string,
  fcmEvent: LiveActivityFcmEvent,
  contentState: Record<string, string | number | boolean>,
  options?: SendOptions,
): Promise<"sent" | "skipped" | "failed"> {
  const dedupAction = options?.dedupAction ?? fcmEvent;
  const cache = options?.dispatchCache;

  if (!options?.skipDedup) {
    const alreadySent = cache
      ? cache.wasDispatched(scheduleId, device.user_id, device.device_id, dedupAction)
      : false;
    if (alreadySent) return "skipped";
  }

  const token = device.fcm_token?.trim();
  if (!token) return "skipped";

  const activityId = `event_${eventId}`;
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
    if (!options?.skipDedup) {
      cache?.markDispatched(
        scheduleId,
        device.user_id,
        device.device_id,
        dedupAction,
      );
    }
    return "sent";
  }

  console.error(`LiveActivity FCM failed ${device.id}: ${result.errorCode}`);
  if (isUnregisteredTokenError(result.errorCode)) {
    await supabase.from("profile_push_devices").delete().eq("id", device.id);
  }
  return "failed";
}

async function loadDevicesForEvent(
  supabase: ReturnType<typeof createClient>,
  event: CalendarEventRow,
): Promise<DeviceRow[]> {
  const { data: devices, error: devicesError } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, device_id, fcm_token, platform, schedule_filter, push_to_start_token, live_activity_push_token, profiles!inner(id, choir, voice)",
    )
    .not("fcm_token", "is", null)
    .or(
      "push_to_start_token.not.is.null,live_activity_push_token.not.is.null",
    );

  if (devicesError) {
    console.error("profile_push_devices query failed", devicesError.message);
    throw new Error(devicesError.message);
  }

  return ((devices ?? []) as DeviceRow[]).filter((device) => {
    const profile = asProfile(device.profiles);
    return profile != null && profileMatchesEvent(profile, event);
  });
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

  if (error) {
    console.error("calendar_events lookup failed", error.message);
    throw new Error(error.message);
  }

  return data as CalendarEventRow | null;
}

async function loadSchedulesForEvent(
  supabase: ReturnType<typeof createClient>,
  eventId: string,
): Promise<ScheduleRow[]> {
  const { data, error } = await supabase
    .from("event_schedules")
    .select("id, event_id, title, location, start_time, end_time, choir, voices")
    .eq("event_id", eventId)
    .order("start_time", { ascending: true });

  if (error) {
    console.error("event_schedules query failed", error.message);
    throw new Error(error.message);
  }

  return (data ?? []) as ScheduleRow[];
}

async function handleDispatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const eventId = request.event_id;
  const action = request.action;
  if (!eventId || (action !== "start" && action !== "end")) {
    return jsonResponse({ error: "event_id and action (start|end) required" }, 400);
  }

  let event: CalendarEventRow | null;
  try {
    event = await loadEvent(supabase, eventId);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  if (!event || !isEventType(event.type)) {
    return jsonResponse({ processed: 0, sent: 0, skipped: 0, mode: "dispatch" });
  }

  let schedules: ScheduleRow[];
  try {
    schedules = await loadSchedulesForEvent(supabase, eventId);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  const hasSchedules = schedules.length > 0;
  const scheduleId = dedupScheduleId(eventId, request.schedule_id);

  let devices: DeviceRow[];
  try {
    devices = await loadDevicesForEvent(supabase, event);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", step: "profile_push_devices", detail: message }, 500);
  }

  const dispatchScheduleIds = hasSchedules
    ? schedules.map((s) => s.id)
    : [eventId];
  const dispatchCache = await DispatchCache.load(
    supabase,
    dispatchScheduleIds,
    ["start", "end"],
  );

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      skipped++;
      continue;
    }

    const filter = device.schedule_filter ?? "all";

    if (!hasSchedules) {
      const snapshot = buildEventOnlySnapshot(event);
      if (!snapshot) {
        skipped++;
        continue;
      }

      if (action === "start") {
        const fcmEvent = resolveSegmentStartEvent(device);
        const result = await sendForDevice(
          supabase,
          serviceAccount,
          device,
          eventId,
          eventId,
          fcmEvent,
          snapshotToContentState(snapshot, eventId),
          { dispatchCache, dedupAction: "start" },
        );
        if (result === "sent") sent++;
        else if (result === "failed") failed++;
        else skipped++;
      } else {
        const result = await sendForDevice(
          supabase,
          serviceAccount,
          device,
          eventId,
          eventId,
          "end",
          snapshotToContentState(snapshot, eventId),
          { dispatchCache },
        );
        if (result === "sent") sent++;
        else if (result === "failed") failed++;
        else skipped++;
      }
      continue;
    }

    const visible = visibleSchedulesToday(schedules, profile, filter, now);
    const targetSchedule = schedules.find((s) => s.id === scheduleId);

    if (action === "start") {
      if (!targetSchedule) {
        skipped++;
        continue;
      }
      const snapshot = buildSnapshot(visible, now);
      if (!snapshot || snapshot.currentScheduleId !== targetSchedule.id) {
        skipped++;
        continue;
      }
      const fcmEvent = resolveSegmentStartEvent(device);
      const result = await sendForDevice(
        supabase,
        serviceAccount,
        device,
        eventId,
        targetSchedule.id,
        fcmEvent,
        snapshotToContentState(snapshot, eventId),
        { dispatchCache, dedupAction: "start" },
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
      continue;
    }

    if (!targetSchedule) {
      skipped++;
      continue;
    }
    if (!isLastVisibleSegmentOfDay(targetSchedule, visible)) {
      skipped++;
      continue;
    }

    const last = visible[visible.length - 1];
    const contentState = snapshotToContentState({
      currentScheduleId: last.id,
      currentTitle: last.title,
      currentSubtitle: last.location ?? "",
      hasNext: false,
      nextTitle: "",
      nextSubtitle: "",
      segmentStartMs: new Date(last.start_time).getTime(),
      segmentEndMs: effectiveEnd(last).getTime(),
    }, eventId);

    const result = await sendForDevice(
      supabase,
      serviceAccount,
      device,
      eventId,
      targetSchedule.id,
      "end",
      contentState,
      { dispatchCache },
    );
    if (result === "sent") sent++;
    else if (result === "failed") failed++;
    else skipped++;
  }

  await dispatchCache.flush(supabase);

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "dispatch",
    event_id: eventId,
    action,
    schedule_id: request.schedule_id ?? null,
    job_id: request.job_id ?? null,
  });
}

async function handleContentChange(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  request: RequestBody,
  now: Date,
): Promise<Response> {
  const eventId = request.event_id;
  if (!eventId) {
    return jsonResponse({ error: "event_id required" }, 400);
  }

  let event: CalendarEventRow | null;
  try {
    event = await loadEvent(
      supabase,
      eventId,
      request.op === "DELETE" ? request.event_snapshot : null,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  if (event && !isEventType(event.type)) {
    return jsonResponse({ processed: 0, sent: 0, skipped: 0, mode: "change" });
  }

  let schedules: ScheduleRow[];
  try {
    schedules = await loadSchedulesForEvent(supabase, eventId);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", detail: message }, 500);
  }

  const isDeleted = request.op === "DELETE" || event == null;
  if (!isDeleted && event && !isEventRelevantToday(event, schedules, now)) {
    return jsonResponse({ processed: 1, sent: 0, skipped: 0, mode: "change" });
  }

  if (isDeleted && !event) {
    return jsonResponse({ processed: 1, sent: 0, skipped: 0, mode: "change" });
  }

  const referenceEvent = event!;
  let devices: DeviceRow[];
  try {
    devices = isDeleted
      ? await loadDevicesForEvent(supabase, referenceEvent)
      : await loadDevicesForEvent(supabase, referenceEvent);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return jsonResponse({ error: "Query failed", step: "profile_push_devices", detail: message }, 500);
  }

  const hasSchedules = schedules.length > 0;
  const dispatchScheduleIds = hasSchedules
    ? schedules.map((s) => s.id)
    : [eventId];
  const dispatchCache = await DispatchCache.load(
    supabase,
    dispatchScheduleIds,
    ["start", "end"],
  );

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const device of devices) {
    const profile = asProfile(device.profiles);
    if (!profile) {
      skipped++;
      continue;
    }

    const endScheduleId = hasSchedules
      ? schedules[schedules.length - 1].id
      : eventId;

    if (isDeleted || !profileMatchesEvent(profile, referenceEvent)) {
      const result = await sendForDevice(
        supabase,
        serviceAccount,
        device,
        eventId,
        endScheduleId,
        "end",
        emptyContentState(eventId),
        { skipDedup: true },
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
      continue;
    }

    const filter = device.schedule_filter ?? "all";

    if (!hasSchedules) {
      const snapshot = buildEventOnlySnapshot(referenceEvent);
      if (!snapshot || !isEventActiveToday(referenceEvent, now)) {
        if (snapshot && new Date(referenceEvent.end_time!) <= now) {
          const result = await sendForDevice(
            supabase,
            serviceAccount,
            device,
            eventId,
            eventId,
            "end",
            snapshotToContentState(snapshot, eventId),
            { skipDedup: true },
          );
          if (result === "sent") sent++;
          else if (result === "failed") failed++;
          else skipped++;
        } else {
          skipped++;
        }
        continue;
      }

      const alreadyStarted = dispatchCache.wasDispatched(
        eventId,
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
        eventId,
        eventId,
        fcmEvent,
        snapshotToContentState(snapshot, eventId),
        {
          dispatchCache,
          skipDedup: fcmEvent === "update",
          dedupAction: "start",
        },
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
      continue;
    }

    const visible = visibleSchedulesToday(schedules, profile, filter, now);
    const snapshot = buildSnapshot(visible, now);

    if (!snapshot) {
      if (visible.length === 0) {
        skipped++;
        continue;
      }
      const last = visible[visible.length - 1];
      const result = await sendForDevice(
        supabase,
        serviceAccount,
        device,
        eventId,
        last.id,
        "end",
        snapshotToContentState({
          currentScheduleId: last.id,
          currentTitle: last.title,
          currentSubtitle: last.location ?? "",
          hasNext: false,
          nextTitle: "",
          nextSubtitle: "",
          segmentStartMs: new Date(last.start_time).getTime(),
          segmentEndMs: effectiveEnd(last).getTime(),
        }, eventId),
        { skipDedup: true },
      );
      if (result === "sent") sent++;
      else if (result === "failed") failed++;
      else skipped++;
      continue;
    }

    const alreadyStarted = dispatchCache.wasDispatched(
      snapshot.currentScheduleId,
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
      eventId,
      snapshot.currentScheduleId,
      fcmEvent,
      snapshotToContentState(snapshot, eventId),
      {
        dispatchCache,
        skipDedup: fcmEvent === "update",
        dedupAction: "start",
      },
    );
    if (result === "sent") sent++;
    else if (result === "failed") failed++;
    else skipped++;
  }

  await dispatchCache.flush(supabase);

  return jsonResponse({
    processed: 1,
    sent,
    failed,
    skipped,
    mode: "change",
    event_id: eventId,
    source: request.source,
    op: request.op,
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

    let serviceAccount;
    try {
      serviceAccount = parseServiceAccountJson(serviceAccountRaw);
    } catch (e) {
      console.error("Firebase service account parse error", e);
      return jsonResponse({ error: "Server configuration error" }, 500);
    }
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const now = new Date();

    let body: RequestBody = {};
    try {
      const rawBody = await req.text();
      if (rawBody.trim().length === 0) {
        return jsonResponse({ error: "Request body required" }, 400);
      }
      body = JSON.parse(rawBody) as RequestBody;
    } catch (e) {
      console.error("request body parse error", e);
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    if (body.mode === "dispatch" && body.event_id) {
      return await handleDispatch(supabase, serviceAccount, body, now);
    }

    if (body.mode === "change" && body.event_id) {
      return await handleContentChange(supabase, serviceAccount, body, now);
    }

    return jsonResponse({ error: "Invalid mode" }, 400);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("schedule-live-activity unhandled", e);
    return jsonResponse({ error: "Unhandled error", detail: message }, 500);
  }
});
