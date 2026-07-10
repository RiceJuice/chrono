import type { LiveActivityFcmEvent } from "../fcm_v1.ts";
import type { LiveActivityKind } from "./types.ts";

export type SkipReason =
  | "already_dispatched"
  | "no_fcm_token"
  | "missing_ios_start_token"
  | "missing_ios_update_token"
  | "no_profile"
  | "no_snapshot"
  | "fcm_failed";

export type DeviceDispatchDetail = {
  device_id: string;
  user_id: string;
  platform: string;
  result: "sent" | "skipped" | "failed";
  skip_reason?: SkipReason;
  error_code?: string;
};

export type DispatchSummary = {
  mode: string;
  kind: LiveActivityKind;
  reference_id: string;
  action?: LiveActivityFcmEvent;
  user_id?: string | null;
  class_name?: string | null;
  schooltrack?: string | null;
  job_id?: string | null;
  users_processed: number;
  devices_total: number;
  sent: number;
  skipped: number;
  failed: number;
  skip_reasons: Partial<Record<SkipReason, number>>;
  duration_ms: number;
  devices?: DeviceDispatchDetail[];
};

const MAX_DEVICE_DETAILS = 20;

export function createDispatchSummary(
  base: Omit<
    DispatchSummary,
    "sent" | "skipped" | "failed" | "skip_reasons" | "duration_ms" | "devices"
  >,
  startedAt: number,
  details: DeviceDispatchDetail[],
): DispatchSummary {
  let sent = 0;
  let skipped = 0;
  let failed = 0;
  const skip_reasons: Partial<Record<SkipReason, number>> = {};

  for (const detail of details) {
    if (detail.result === "sent") sent++;
    else if (detail.result === "failed") failed++;
    else skipped++;

    if (detail.skip_reason) {
      skip_reasons[detail.skip_reason] = (skip_reasons[detail.skip_reason] ?? 0) + 1;
    }
  }

  const summary: DispatchSummary = {
    ...base,
    sent,
    skipped,
    failed,
    skip_reasons,
    duration_ms: Date.now() - startedAt,
  };

  if (details.length > 0 && details.length <= MAX_DEVICE_DETAILS) {
    summary.devices = details;
  }

  return summary;
}

/** Strukturiertes Log für Supabase Edge Function Logs (console). */
export function logDispatchSummary(summary: DispatchSummary): void {
  const line = JSON.stringify({
    tag: "live_activity_dispatch",
    ...summary,
  });
  console.log(line);

  if (summary.failed > 0) {
    console.warn(
      `live_activity_dispatch: ${summary.failed} failed, ${summary.sent} sent, ${summary.skipped} skipped` +
        ` (${summary.kind}/${summary.action ?? "?"} ${summary.reference_id})`,
    );
  }
}
