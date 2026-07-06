import type { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  isUnregisteredTokenError,
  sendLiveActivityFcm,
  type LiveActivityFcmEvent,
} from "../fcm_v1.ts";
import type { FirebaseServiceAccount } from "../fcm_v1.ts";
import type { DeviceRow, LiveActivityKind } from "./types.ts";

export type SendResult = "sent" | "skipped" | "failed";

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
  if (!options.skipDedup) {
    const already = await wasDispatched(
      supabase,
      options.dedupTable,
      options.dedupKey,
      options.fcmEvent,
    );
    if (already) return "skipped";
  }

  const token = device.fcm_token?.trim();
  if (!token) return "skipped";

  const activityId = options.kind === "timetable"
    ? `timetable_${options.referenceId}`
    : `event_${options.referenceId}`;

  const result = await sendLiveActivityFcm(serviceAccount, {
    token,
    platform: device.platform,
    event: options.fcmEvent,
    activityId,
    contentState: options.contentState,
    eventId: options.referenceId,
    dayDate: options.dayDate,
    activityType: options.activityType,
    liveActivityPushToken: device.live_activity_push_token,
    pushToStartToken: device.push_to_start_token,
  });

  if (result.ok) {
    if (!options.skipDedup) {
      await markDispatched(
        supabase,
        options.dedupTable,
        options.dedupKey,
        options.fcmEvent,
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

async function wasDispatched(
  supabase: ReturnType<typeof createClient>,
  table: string,
  key: Record<string, string>,
  action: LiveActivityFcmEvent,
): Promise<boolean> {
  if (table === "schedule_live_activity_dispatches") {
    const { data } = await supabase
      .from(table)
      .select("id")
      .eq("schedule_id", key.schedule_id)
      .eq("user_id", key.user_id)
      .eq("device_id", key.device_id)
      .eq("action", action)
      .maybeSingle();
    return data != null;
  }

  const { data } = await supabase
    .from(table)
    .select("id")
    .eq("day_date", key.day_date)
    .eq("user_id", key.user_id)
    .eq("device_id", key.device_id)
    .eq("action", action)
    .maybeSingle();
  return data != null;
}

async function markDispatched(
  supabase: ReturnType<typeof createClient>,
  table: string,
  key: Record<string, string>,
  action: LiveActivityFcmEvent,
): Promise<void> {
  if (table === "schedule_live_activity_dispatches") {
    await supabase.from(table).upsert({
      schedule_id: key.schedule_id,
      user_id: key.user_id,
      device_id: key.device_id,
      action,
      sent_at: new Date().toISOString(),
    }, { onConflict: "schedule_id,user_id,device_id,action" });
    return;
  }

  await supabase.from(table).upsert({
    day_date: key.day_date,
    user_id: key.user_id,
    device_id: key.device_id,
    action,
    sent_at: new Date().toISOString(),
  }, { onConflict: "day_date,user_id,device_id,action" });
}
