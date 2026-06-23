/**
 * FCM for guardian-child link requests and confirmations.
 * Invoked by the app after creating/responding to a link.
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

type NotifyBody = {
  link_id?: string;
  action?: "request" | "confirmed" | "reminder";
};

type LinkRow = {
  id: string;
  guardian_id: string;
  child_id: string;
  status: string;
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
  supabase: ReturnType<typeof createClient>,
  serviceAccount: ReturnType<typeof parseServiceAccountJson>,
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ sent: number; failed: number; clearedInvalidTokens: number }> {
  const { data: devices, error } = await supabase
    .from("profile_push_devices")
    .select("id, user_id, fcm_token")
    .eq("user_id", userId);

  if (error) {
    console.error("device query failed", error.message);
    return { sent: 0, failed: 0, clearedInvalidTokens: 0 };
  }

  let sent = 0;
  let failed = 0;
  let clearedInvalidTokens = 0;

  for (const row of (devices ?? []) as PushDeviceRow[]) {
    const token = row.fcm_token?.trim();
    if (!token) continue;

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
    if (isUnregisteredTokenError(result.errorCode)) {
      const { error: clearError } = await supabase
        .from("profile_push_devices")
        .delete()
        .eq("id", row.id);
      if (!clearError) clearedInvalidTokens++;
    }
  }

  return { sent, failed, clearedInvalidTokens };
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

  const callerId = userData.user.id;

  let body: NotifyBody;
  try {
    body = (await req.json()) as NotifyBody;
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const linkId = body.link_id?.trim();
  const action = body.action?.trim();

  if (!linkId || !action) {
    return jsonResponse({ error: "link_id and action are required" }, 400);
  }

  if (!["request", "confirmed", "reminder"].includes(action)) {
    return jsonResponse({ error: "Invalid action" }, 400);
  }

  const { data: link, error: linkError } = await supabase
    .from("guardian_child_links")
    .select("id, guardian_id, child_id, status")
    .eq("id", linkId)
    .maybeSingle();

  if (linkError || !link) {
    return jsonResponse({ error: "Link not found" }, 404);
  }

  const linkRow = link as LinkRow;

  if (action === "request" || action === "reminder") {
    if (linkRow.guardian_id !== callerId) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }
    if (linkRow.status !== "pending") {
      return jsonResponse({ error: "Link is not pending" }, 400);
    }
  }

  if (action === "confirmed") {
    if (linkRow.child_id !== callerId && linkRow.guardian_id !== callerId) {
      return jsonResponse({ error: "Forbidden" }, 403);
    }
    if (linkRow.status !== "confirmed") {
      return jsonResponse({ error: "Link is not confirmed" }, 400);
    }
  }

  let serviceAccount;
  try {
    serviceAccount = parseServiceAccountJson(serviceAccountRaw);
  } catch (e) {
    console.error("Firebase service account parse error", e);
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const { data: guardianProfile } = await supabase
    .from("profiles")
    .select("id, first_name, last_name")
    .eq("id", linkRow.guardian_id)
    .maybeSingle();

  const { data: childProfile } = await supabase
    .from("profiles")
    .select("id, first_name, last_name")
    .eq("id", linkRow.child_id)
    .maybeSingle();

  const guardianName = formatName(guardianProfile as ProfileRow | null);
  const childName = formatName(childProfile as ProfileRow | null);

  if (action === "request" || action === "reminder") {
    const result = await sendToUserDevices(
      supabase,
      serviceAccount,
      linkRow.child_id,
      "Eltern-Verknüpfung",
      `${guardianName} möchte sich als Elternteil mit dir verknüpfen.`,
      {
        type: "guardian_link_request",
        link_id: linkId,
        guardian_name: guardianName,
      },
    );

    if (action === "reminder") {
      await supabase
        .from("guardian_child_links")
        .update({ reminder_sent_at: new Date().toISOString() })
        .eq("id", linkId);
    }

    return jsonResponse(result);
  }

  // confirmed → notify guardian
  const result = await sendToUserDevices(
    supabase,
    serviceAccount,
    linkRow.guardian_id,
    "Verknüpfung bestätigt",
    `${childName} hat die Verknüpfung bestätigt.`,
    {
      type: "guardian_link_confirmed",
      link_id: linkId,
      child_name: childName,
    },
  );

  return jsonResponse(result);
});
