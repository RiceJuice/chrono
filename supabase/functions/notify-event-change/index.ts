/**
 * Authenticated admin → FCM to affected users after calendar event edit.
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
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AudiencePayload = {
  choir?: string | null;
  voices?: string[] | null;
  schooltrack?: string | null;
  class_name?: string | null;
  diet?: string | null;
};

type ChangePayload = {
  label?: string;
  old?: string;
  new?: string;
};

type NotifyBody = {
  event_id?: string;
  event_name?: string;
  event_type?: string;
  audience_before?: AudiencePayload;
  audience_after?: AudiencePayload;
  changes?: ChangePayload[];
};

type ProfileRow = {
  id: string;
  choir: string | null;
  voice: string | null;
  schooltrack: string | null;
  class_name: string | null;
  diet: string | null;
  role: string | null;
};

type PushDeviceRow = {
  id: string;
  user_id: string;
  fcm_token: string;
  platform: string;
  profiles: ProfileRow;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeText(value: string | null | undefined): string | null {
  if (value == null) return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed.toLowerCase() : null;
}

function audienceHasCriteria(audience: AudiencePayload): boolean {
  return !!(
    normalizeText(audience.choir) ||
    (audience.voices?.length ?? 0) > 0 ||
    normalizeText(audience.schooltrack) ||
    normalizeText(audience.class_name) ||
    normalizeText(audience.diet)
  );
}

function profileMatchesAudience(
  profile: ProfileRow,
  audience: AudiencePayload,
  eventType: string,
): boolean {
  if (!audienceHasCriteria(audience)) return false;

  const choir = normalizeText(audience.choir);
  if (choir && normalizeText(profile.choir) !== choir) return false;

  const voices = (audience.voices ?? [])
    .map((v) => normalizeText(v))
    .filter((v): v is string => v != null);
  if (voices.length > 0) {
    const profileVoice = normalizeText(profile.voice);
    if (!profileVoice || !voices.includes(profileVoice)) return false;
  }

  const schoolTrack = normalizeText(audience.schooltrack);
  if (schoolTrack && normalizeText(profile.schooltrack) !== schoolTrack) {
    return false;
  }

  const className = normalizeText(audience.class_name);
  if (className && normalizeText(profile.class_name) !== className) {
    return false;
  }

  const diet = normalizeText(audience.diet);
  if (diet && eventType === "meal") {
    if (normalizeText(profile.diet) !== diet) return false;
  }

  return true;
}

function formatChangeBody(
  eventName: string,
  changes: ChangePayload[],
  maxLen = 200,
): string {
  if (changes.length === 0) {
    return `„${eventName}" wurde angepasst.`;
  }

  const parts = changes
    .filter((c) => c.label?.trim())
    .map((c) => {
      const label = c.label!.trim();
      const oldVal = (c.old ?? "—").trim() || "—";
      const newVal = (c.new ?? "—").trim() || "—";
      return `${label}: ${oldVal} → ${newVal}`;
    });

  if (parts.length === 0) {
    return `„${eventName}" wurde angepasst.`;
  }

  let body = parts.join("; ");
  if (body.length > maxLen) {
    body = `${body.slice(0, maxLen - 1).trim()}…`;
  }
  return body;
}

function formatRemovalBody(eventName: string): string {
  return `„${eventName}" betrifft dich nicht mehr.`;
}

async function sendToDevices(
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  devices: PushDeviceRow[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{
  sent: number;
  failed: number;
  skipped: number;
  clearedInvalidTokens: number;
}> {
  let sent = 0;
  let failed = 0;
  let skipped = 0;
  let clearedInvalidTokens = 0;

  for (const row of devices) {
    const token = row.fcm_token?.trim();
    if (!token) {
      skipped++;
      continue;
    }

    const result = await sendFcmToToken(
      serviceAccount,
      token,
      title,
      body,
      data,
    );

    if (result.ok) {
      sent++;
      continue;
    }

    failed++;
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

  return { sent, failed, skipped, clearedInvalidTokens };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

  if (!supabaseUrl || !serviceRoleKey || !serviceAccountRaw) {
    console.error("Missing env configuration");
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const jwt = authHeader.slice("Bearer ".length);

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser(jwt);
  if (userError || !userData.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const editorId = userData.user.id;

  const { data: editorProfile, error: editorProfileError } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", editorId)
    .maybeSingle();

  if (editorProfileError || editorProfile?.role?.trim() !== "Admin") {
    return jsonResponse({ error: "Forbidden" }, 403);
  }

  let body: NotifyBody;
  try {
    body = (await req.json()) as NotifyBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const eventId = body.event_id?.trim();
  const eventName = body.event_name?.trim();
  const eventType = body.event_type?.trim() || "event";
  const audienceBefore = body.audience_before ?? {};
  const audienceAfter = body.audience_after ?? {};
  const changes = body.changes ?? [];

  if (!eventId || !eventName) {
    return jsonResponse({ error: "event_id and event_name are required" }, 400);
  }

  let serviceAccount;
  try {
    serviceAccount = parseServiceAccountJson(serviceAccountRaw);
  } catch (e) {
    console.error("Firebase service account parse error", e);
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const { data: devices, error: queryError } = await supabase
    .from("profile_push_devices")
    .select(
      "id, user_id, fcm_token, platform, profiles!inner(id, choir, voice, schooltrack, class_name, diet, role)",
    );

  if (queryError) {
    console.error("profile_push_devices query failed", queryError.message);
    return jsonResponse({ error: "Failed to load device tokens" }, 500);
  }

  const rows = (devices ?? []) as PushDeviceRow[];

  const removedDevices: PushDeviceRow[] = [];
  const changeDevices: PushDeviceRow[] = [];

  for (const row of rows) {
    if (row.user_id === editorId) continue;

    const profile = row.profiles;
    const matchedBefore = profileMatchesAudience(
      profile,
      audienceBefore,
      eventType,
    );
    const matchedAfter = profileMatchesAudience(
      profile,
      audienceAfter,
      eventType,
    );

    if (matchedBefore && !matchedAfter) {
      removedDevices.push(row);
    }
    if (matchedAfter) {
      changeDevices.push(row);
    }
  }

  const fcmData = {
    type: "event_change",
    event_id: eventId,
  };

  let sent = 0;
  let failed = 0;
  let skipped = 0;
  let clearedInvalidTokens = 0;

  if (removedDevices.length > 0) {
    const removalResult = await sendToDevices(
      supabase,
      serviceAccount,
      removedDevices,
      `Termin entfernt: ${eventName}`,
      formatRemovalBody(eventName),
      fcmData,
    );
    sent += removalResult.sent;
    failed += removalResult.failed;
    skipped += removalResult.skipped;
    clearedInvalidTokens += removalResult.clearedInvalidTokens;
  }

  if (changeDevices.length > 0) {
    const changeResult = await sendToDevices(
      supabase,
      serviceAccount,
      changeDevices,
      `Termin geändert: ${eventName}`,
      formatChangeBody(eventName, changes),
      fcmData,
    );
    sent += changeResult.sent;
    failed += changeResult.failed;
    skipped += changeResult.skipped;
    clearedInvalidTokens += changeResult.clearedInvalidTokens;
  }

  const removedUserIds = new Set(removedDevices.map((d) => d.user_id));
  const changeUserIds = new Set(changeDevices.map((d) => d.user_id));

  return jsonResponse({
    sent,
    failed,
    skipped,
    removed_count: removedUserIds.size,
    changed_count: changeUserIds.size,
    removed_device_count: removedDevices.length,
    changed_device_count: changeDevices.length,
    cleared_invalid_tokens: clearedInvalidTokens,
  });
});
