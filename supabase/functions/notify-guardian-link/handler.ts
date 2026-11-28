/**
 * FCM for guardian-child link requests and confirmations.
 * Drains persisted outbox jobs; invoked by a scheduled worker or participant.
 */

import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.49.1";
import {
  isUnregisteredTokenError,
  parseServiceAccountJson,
  sendFcmToToken,
} from "../_shared/fcm_v1.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ProfileRow = {
  id: string;
  first_name: string | null;
  last_name: string | null;
};

type PushDeviceRow = {
  id: string;
  user_id: string;
  fcm_token: string;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function formatName(profile: ProfileRow | null): string {
  if (!profile) return "Jemand";
  const parts = [profile.first_name, profile.last_name]
    .map((p) => p?.trim())
    .filter((p): p is string => !!p);
  return parts.length > 0 ? parts.join(" ") : "Jemand";
}

async function sendToUserDevices(
  supabase: SupabaseClient,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>,
  jobId: string,
  send: typeof sendFcmToToken,
): Promise<{ sent: number; failed: number; clearedInvalidTokens: number }> {
  const { data: devices, error } = await supabase
    .from("profile_push_devices")
    .select("id, user_id, fcm_token")
    .eq("user_id", userId);

  if (error) {
    console.error("guardian_device_lookup_failed", { code: error.code });
    throw new Error("Device lookup failed");
  }

  let sent = 0;
  let failed = 0;
  let clearedInvalidTokens = 0;

  for (const row of (devices ?? []) as PushDeviceRow[]) {
    const { data: delivered, error: deliveryError } = await supabase.rpc(
      "guardian_notification_device_accepted",
      { p_job: jobId, p_device: row.id },
    );
    if (deliveryError) throw new Error("Delivery lookup failed");
    if (delivered === true) {
      sent++;
      continue;
    }
    const token = row.fcm_token?.trim();
    if (!token) continue;

    const result = await send(
      serviceAccount,
      token,
      title,
      body,
      data,
    );

    if (result.ok) {
      const { error: recordError } = await supabase.rpc(
        "record_guardian_notification_device",
        { p_job: jobId, p_device: row.id },
      );
      if (recordError) throw new Error("Delivery record failed");
      sent++;
      continue;
    }

    failed++;
    if (isUnregisteredTokenError(result.errorCode)) {
      const { error: clearError } = await supabase
        .from("profile_push_devices")
        .delete()
        .eq("id", row.id).eq("fcm_token", token);
      if (!clearError) clearedInvalidTokens++;
    }
  }

  return { sent, failed, clearedInvalidTokens };
}

export async function handleGuardianNotification(
  req: Request,
  send: typeof sendFcmToToken = sendFcmToToken,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }
  const url = Deno.env.get("SUPABASE_URL"),
    key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!url || !key || !raw) {
    return jsonResponse({ error: "Server configuration error" }, 500);
  }
  const token = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!token) return jsonResponse({ error: "Unauthorized" }, 401);
  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  let body: { link_id?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }
  const worker = token === key;
  if (!worker) {
    const { data, error } = await client.auth.getUser(token);
    if (error || !data.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
    if (!body.link_id) return jsonResponse({ error: "Link required" }, 400);
    const { data: link } = await client.from("guardian_child_links").select(
      "guardian_id,child_id",
    ).eq("id", body.link_id).maybeSingle();
    if (!link || ![link.guardian_id, link.child_id].includes(data.user.id)) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }
  }
  const { data: jobs, error } = await client.rpc(
    "claim_guardian_notifications",
    { p_link_id: body.link_id ?? null },
  );
  if (error) return jsonResponse({ error: "Outbox unavailable" }, 503);
  let account;
  try {
    account = parseServiceAccountJson(raw);
  } catch {
    return jsonResponse({ error: "Server configuration error" }, 500);
  }
  let accepted = 0, failed = 0, noDevices = 0;
  for (const job of jobs ?? []) {
    try {
      const { data: link, error: linkError } = await client.from(
        "guardian_child_links",
      )
        .select(
          "id,guardian_id,child_id,status,revision,requested_at,guardian_first_name,guardian_last_name",
        ).eq("id", job.link_id).maybeSingle();
      if (linkError) throw new Error("Link lookup failed");
      const request = job.action === "request" || job.action === "reminder";
      const expected = request ? "pending" : job.action;
      if (
        !link || link.status !== expected ||
        link.requested_at !== job.request_generation || job.action === "revoked"
      ) {
        await client.rpc("finish_guardian_notification", {
          p_id: job.id,
          p_attempt: job.attempts,
          p_accepted: 0,
          p_failed: 0,
          p_retry: false,
        });
        continue;
      }
      const name = formatName({
        id: link.guardian_id,
        first_name: link.guardian_first_name,
        last_name: link.guardian_last_name,
      });
      const result = await sendToUserDevices(
        client,
        account,
        request ? link.child_id : link.guardian_id,
        request ? "Verknüpfungsanfrage" : "Verknüpfung aktualisiert",
        request
          ? `${name} möchte sich mit dir verknüpfen. Prüfe die Anfrage in Chrono.`
          : "Öffne Chrono, um den aktuellen Status zu sehen.",
        {
          type: request
            ? "guardian_link_request"
            : `guardian_link_${job.action}`,
          link_id: link.id,
        },
        job.id,
        send,
      );
      accepted += result.sent;
      failed += result.failed;
      if (result.sent === 0 && result.failed === 0) noDevices++;
      const { error: finishError } = await client.rpc(
        "finish_guardian_notification",
        {
          p_id: job.id,
          p_attempt: job.attempts,
          p_accepted: result.sent,
          p_failed: result.failed,
          p_retry: result.failed > 0 || result.sent === 0,
        },
      );
      if (finishError) throw new Error("Outbox completion failed");
    } catch {
      failed++;
      await client.rpc("finish_guardian_notification", {
        p_id: job.id,
        p_attempt: job.attempts,
        p_accepted: 0,
        p_failed: 1,
        p_retry: true,
      });
    }
  }
  return jsonResponse({
    accepted,
    failed,
    no_devices: noDevices,
    processed: jobs?.length ?? 0,
  });
}
