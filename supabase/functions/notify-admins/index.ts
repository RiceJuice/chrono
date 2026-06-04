/**
 * Webhook: n8n → notify all admins via FCM (alle Geräte in profile_push_devices).
 */

import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  isUnregisteredTokenError,
  parseServiceAccountJson,
  sendFcmToToken,
} from "../_shared/fcm_v1.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-webhook-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type NotifyBody = {
  title?: string;
  body?: string;
  data?: Record<string, string>;
};

type PushDeviceRow = {
  id: string;
  user_id: string;
  fcm_token: string;
  platform: string;
  profiles: { role: string };
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeData(
  data: Record<string, unknown> | undefined,
): Record<string, string> | undefined {
  if (!data || typeof data !== "object") return undefined;
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) {
    if (v != null) out[k] = String(v);
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const webhookSecret = Deno.env.get("N8N_WEBHOOK_SECRET");
  const providedSecret = req.headers.get("x-webhook-secret");
  if (!webhookSecret || providedSecret !== webhookSecret) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!serviceAccountRaw || !supabaseUrl || !serviceRoleKey) {
    console.error(
      "Missing env: FIREBASE_SERVICE_ACCOUNT_JSON, SUPABASE_URL, or SERVICE_ROLE",
    );
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  let body: NotifyBody;
  try {
    body = (await req.json()) as NotifyBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const title = body.title?.trim();
  const notificationBody = body.body?.trim();
  if (!title || !notificationBody) {
    return jsonResponse({ error: "title and body are required" }, 400);
  }

  const data = normalizeData(body.data as Record<string, unknown> | undefined);

  let serviceAccount;
  try {
    serviceAccount = parseServiceAccountJson(serviceAccountRaw);
  } catch (e) {
    console.error("Firebase service account parse error", e);
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: devices, error: queryError } = await supabase
    .from("profile_push_devices")
    .select("id, user_id, fcm_token, platform, profiles!inner(role)")
    .eq("profiles.role", "Admin");

  if (queryError) {
    console.error("profile_push_devices query failed", queryError.message);
    return jsonResponse({ error: "Failed to load admin device tokens" }, 500);
  }

  const rows = (devices ?? []) as PushDeviceRow[];
  const adminUserIds = new Set(rows.map((r) => r.user_id));

  let sent = 0;
  let failed = 0;
  let skipped = 0;
  let clearedInvalidTokens = 0;
  const failures: Array<{
    user_id: string;
    device_id: string;
    platform: string;
    error_code?: string;
    error_message?: string;
  }> = [];

  for (const row of rows) {
    const token = row.fcm_token?.trim();
    if (!token) {
      skipped++;
      continue;
    }

    const result = await sendFcmToToken(
      serviceAccount,
      token,
      title,
      notificationBody,
      data,
    );

    if (result.ok) {
      sent++;
      continue;
    }

    failed++;
    failures.push({
      user_id: row.user_id,
      device_id: row.id,
      platform: row.platform,
      error_code: result.errorCode,
      error_message: result.errorMessage,
    });
    console.error(
      `FCM failed device ${row.id} user ${row.user_id}: ${result.errorCode ?? "unknown"}`,
    );

    if (isUnregisteredTokenError(result.errorCode)) {
      const { error: clearError } = await supabase
        .from("profile_push_devices")
        .delete()
        .eq("id", row.id);
      if (!clearError) clearedInvalidTokens++;
    }
  }

  return jsonResponse({
    sent,
    failed,
    skipped,
    admin_count: adminUserIds.size,
    device_count: rows.length,
    cleared_invalid_tokens: clearedInvalidTokens,
    failures: failures.length > 0 ? failures : undefined,
  });
});
