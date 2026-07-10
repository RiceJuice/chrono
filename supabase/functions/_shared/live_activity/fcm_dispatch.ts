import type { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  isUnregisteredTokenError,
  sendLiveActivityFcm,
  type LiveActivityFcmEvent,
} from "../fcm_v1.ts";
import type { FirebaseServiceAccount } from "../fcm_v1.ts";
import type { DeviceDispatchDetail, SkipReason } from "./dispatch_log.ts";
import type { DeviceRow, LiveActivityKind } from "./types.ts";

export type SendResult = "sent" | "skipped" | "failed";

export type DispatchTarget = {
  device: DeviceRow;
  fcmEvent: LiveActivityFcmEvent;
  contentState: Record<string, string | number | boolean>;
  dedupKey: Record<string, string>;
};

export type BatchDispatchOptions = {
  kind: LiveActivityKind;
  referenceId: string;
  activityType: string;
  dayDate?: string;
  dedupTable: "schedule_live_activity_dispatches" | "timetable_live_activity_dispatches";
  skipDedup?: boolean;
  concurrency?: number;
};

const DEFAULT_CONCURRENCY = 12;

function deviceDetail(
  device: DeviceRow,
  result: DeviceDispatchDetail["result"],
  extra?: Partial<DeviceDispatchDetail>,
): DeviceDispatchDetail {
  return {
    device_id: device.device_id,
    user_id: device.user_id,
    platform: device.platform,
    result,
    ...extra,
  };
}

export function evaluateDeviceReadiness(
  device: DeviceRow,
  fcmEvent: LiveActivityFcmEvent,
): SkipReason | null {
  if (!device.fcm_token?.trim()) return "no_fcm_token";

  if (device.platform === "ios") {
    const hasPushToStart = !!device.push_to_start_token?.trim();
    const hasLiveActivityToken = !!device.live_activity_push_token?.trim();
    if (fcmEvent === "start" && !hasPushToStart) return "missing_ios_start_token";
    if (
      (fcmEvent === "update" || fcmEvent === "end") &&
      !hasLiveActivityToken
    ) {
      return "missing_ios_update_token";
    }
  }

  return null;
}

export async function loadDispatchedDeviceKeys(
  supabase: ReturnType<typeof createClient>,
  table: BatchDispatchOptions["dedupTable"],
  keys: Record<string, string>[],
  action: LiveActivityFcmEvent,
): Promise<Set<string>> {
  if (keys.length === 0) return new Set();

  const dispatched = new Set<string>();

  if (table === "schedule_live_activity_dispatches") {
    const scheduleIds = [...new Set(keys.map((k) => k.schedule_id))];
    const userIds = [...new Set(keys.map((k) => k.user_id))];

    const { data, error } = await supabase
      .from(table)
      .select("schedule_id, user_id, device_id")
      .eq("action", action)
      .in("schedule_id", scheduleIds)
      .in("user_id", userIds);

    if (error) throw new Error(error.message);

    for (const row of data ?? []) {
      dispatched.add(`${row.schedule_id}:${row.user_id}:${row.device_id}`);
    }
    return dispatched;
  }

  const dayDates = [...new Set(keys.map((k) => k.day_date))];
  const userIds = [...new Set(keys.map((k) => k.user_id))];

  const { data, error } = await supabase
    .from(table)
    .select("day_date, user_id, device_id")
    .eq("action", action)
    .in("day_date", dayDates)
    .in("user_id", userIds);

  if (error) throw new Error(error.message);

  for (const row of data ?? []) {
    dispatched.add(`${row.day_date}:${row.user_id}:${row.device_id}`);
  }

  return dispatched;
}

function dedupLookupKey(
  table: BatchDispatchOptions["dedupTable"],
  dedupKey: Record<string, string>,
): string {
  if (table === "schedule_live_activity_dispatches") {
    return `${dedupKey.schedule_id}:${dedupKey.user_id}:${dedupKey.device_id}`;
  }
  return `${dedupKey.day_date}:${dedupKey.user_id}:${dedupKey.device_id}`;
}

async function markDispatchedBatch(
  supabase: ReturnType<typeof createClient>,
  table: BatchDispatchOptions["dedupTable"],
  rows: Array<{ key: Record<string, string>; action: LiveActivityFcmEvent }>,
): Promise<void> {
  if (rows.length === 0) return;

  const sentAt = new Date().toISOString();

  if (table === "schedule_live_activity_dispatches") {
    await supabase.from(table).upsert(
      rows.map(({ key, action }) => ({
        schedule_id: key.schedule_id,
        user_id: key.user_id,
        device_id: key.device_id,
        action,
        sent_at: sentAt,
      })),
      { onConflict: "schedule_id,user_id,device_id,action" },
    );
    return;
  }

  await supabase.from(table).upsert(
    rows.map(({ key, action }) => ({
      day_date: key.day_date,
      user_id: key.user_id,
      device_id: key.device_id,
      action,
      sent_at: sentAt,
    })),
    { onConflict: "day_date,user_id,device_id,action" },
  );
}

async function deleteUnregisteredDevices(
  supabase: ReturnType<typeof createClient>,
  deviceIds: string[],
): Promise<void> {
  if (deviceIds.length === 0) return;
  await supabase.from("profile_push_devices").delete().in("id", deviceIds);
}

async function mapWithConcurrency<T, R>(
  items: T[],
  concurrency: number,
  fn: (item: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let nextIndex = 0;

  async function worker(): Promise<void> {
    while (true) {
      const index = nextIndex++;
      if (index >= items.length) return;
      results[index] = await fn(items[index]);
    }
  }

  const workers = Array.from(
    { length: Math.min(concurrency, items.length) },
    () => worker(),
  );
  await Promise.all(workers);
  return results;
}

export async function sendLiveActivityBatch(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: FirebaseServiceAccount,
  targets: DispatchTarget[],
  options: BatchDispatchOptions,
): Promise<DeviceDispatchDetail[]> {
  if (targets.length === 0) return [];

  const concurrency = options.concurrency ?? DEFAULT_CONCURRENCY;
  const details: DeviceDispatchDetail[] = [];
  const pending: DispatchTarget[] = [];

  let dispatchedKeys: Set<string> | null = null;
  if (!options.skipDedup && targets.length > 0) {
    dispatchedKeys = await loadDispatchedDeviceKeys(
      supabase,
      options.dedupTable,
      targets.map((t) => t.dedupKey),
      targets[0].fcmEvent,
    );
  }

  for (const target of targets) {
    const readiness = evaluateDeviceReadiness(target.device, target.fcmEvent);
    if (readiness) {
      details.push(deviceDetail(target.device, "skipped", { skip_reason: readiness }));
      continue;
    }

    if (
      dispatchedKeys &&
      dispatchedKeys.has(dedupLookupKey(options.dedupTable, target.dedupKey))
    ) {
      details.push(
        deviceDetail(target.device, "skipped", { skip_reason: "already_dispatched" }),
      );
      continue;
    }

    pending.push(target);
  }

  const activityIdPrefix = options.kind === "timetable" ? "timetable_" : "event_";

  const sendResults = await mapWithConcurrency(pending, concurrency, async (target) => {
    const { device, fcmEvent, contentState } = target;
    const activityId = `${activityIdPrefix}${options.referenceId}`;

    const result = await sendLiveActivityFcm(serviceAccount, {
      token: device.fcm_token.trim(),
      platform: device.platform,
      event: fcmEvent,
      activityId,
      contentState,
      eventId: options.referenceId,
      dayDate: options.dayDate,
      activityType: options.activityType,
      liveActivityPushToken: device.live_activity_push_token,
      pushToStartToken: device.push_to_start_token,
    });

    return { target, result };
  });

  const toMark: Array<{ key: Record<string, string>; action: LiveActivityFcmEvent }> = [];
  const toDelete: string[] = [];

  for (const { target, result } of sendResults) {
    if (result.ok) {
      if (!options.skipDedup) {
        toMark.push({ key: target.dedupKey, action: target.fcmEvent });
      }
      details.push(deviceDetail(target.device, "sent"));
      continue;
    }

    console.error(
      `LiveActivity FCM failed ${target.device.id}: ${result.errorCode} ${result.errorMessage}`,
    );

    if (isUnregisteredTokenError(result.errorCode)) {
      toDelete.push(target.device.id);
    }

    details.push(
      deviceDetail(target.device, "failed", {
        skip_reason: "fcm_failed",
        error_code: result.errorCode,
      }),
    );
  }

  await Promise.all([
    markDispatchedBatch(supabase, options.dedupTable, toMark),
    deleteUnregisteredDevices(supabase, toDelete),
  ]);

  return details;
}

/** Einzelversand – nutzt dieselbe Logik wie der Batch-Pfad. */
export async function sendLiveActivityToDevice(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: FirebaseServiceAccount,
  device: DeviceRow,
  options: {
    kind: LiveActivityKind;
    referenceId: string;
    fcmEvent: LiveActivityFcmEvent;
    contentState: Record<string, string | number | boolean>;
    activityType: string;
    dayDate?: string;
    dedupTable: "schedule_live_activity_dispatches" | "timetable_live_activity_dispatches";
    dedupKey: Record<string, string>;
    skipDedup?: boolean;
  },
): Promise<SendResult> {
  const [detail] = await sendLiveActivityBatch(
    supabase,
    serviceAccount,
    [{
      device,
      fcmEvent: options.fcmEvent,
      contentState: options.contentState,
      dedupKey: options.dedupKey,
    }],
    {
      kind: options.kind,
      referenceId: options.referenceId,
      activityType: options.activityType,
      dayDate: options.dayDate,
      dedupTable: options.dedupTable,
      skipDedup: options.skipDedup,
      concurrency: 1,
    },
  );

  return detail?.result ?? "skipped";
}
