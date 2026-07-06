/**
 * Legacy-Redirect → live-activity (Stundenplan).
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const LIVE_ACTIVITY_URL = Deno.env.get("SUPABASE_URL") +
  "/functions/v1/live-activity";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const cronSecret = req.headers.get("x-cron-secret");
  const rawBody = await req.text();
  let body: Record<string, unknown> = {};
  try {
    if (rawBody.trim()) body = JSON.parse(rawBody);
  } catch {
    body = {};
  }

  const forwarded = body.mode === "change"
    ? { mode: "change", kind: "timetable", reference_id: body.reference_id }
    : {
      mode: "dispatch",
      kind: "timetable",
      reference_id: body.reference_id ?? body.day_date,
      user_id: body.user_id,
      action: body.action ?? "start",
    };

  const res = await fetch(LIVE_ACTIVITY_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-cron-secret": cronSecret ?? "",
    },
    body: JSON.stringify(forwarded),
  });

  return new Response(await res.text(), {
    status: res.status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
