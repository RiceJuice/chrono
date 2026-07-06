/**
 * Löscht den angemeldeten Nutzer nach Passwort- bzw. E-Mail-Bestätigung.
 * Erfordert gültiges Nutzer-JWT (verify_jwt = true).
 */

import { createClient } from "npm:@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type DeleteAccountBody = {
  password?: string;
  confirmationEmail?: string;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function hasEmailIdentity(identities: { provider: string }[] | undefined): boolean {
  if (!identities?.length) return false;
  return identities.some((identity) => identity.provider === "email");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Nicht angemeldet." }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const supabaseUser = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabaseUser.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: "Nicht angemeldet." }, 401);
    }

    const body = (await req.json()) as DeleteAccountBody;
    const email = user.email?.trim().toLowerCase();

    if (hasEmailIdentity(user.identities)) {
      const password = body.password?.trim();
      if (!password) {
        return jsonResponse({ error: "Passwort erforderlich." }, 400);
      }
      if (!email) {
        return jsonResponse({ error: "Keine E-Mail-Adresse hinterlegt." }, 400);
      }

      const verifyClient = createClient(supabaseUrl, anonKey);
      const { error: signInError } = await verifyClient.auth.signInWithPassword({
        email,
        password,
      });
      if (signInError) {
        return jsonResponse({ error: "Passwort ist ungültig." }, 403);
      }
    } else {
      const confirmed = body.confirmationEmail?.trim().toLowerCase();
      if (!email || !confirmed || confirmed !== email) {
        return jsonResponse(
          { error: "E-Mail-Adresse stimmt nicht überein." },
          403,
        );
      }
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const userId = user.id;
    const prefix = `${userId}-`;

    const { data: bucketFiles, error: listError } = await supabaseAdmin.storage
      .from("uploads")
      .list("", { search: prefix, limit: 1000 });

    if (listError) {
      console.error("uploads list failed:", listError.message);
    } else {
      const ownFiles = (bucketFiles ?? [])
        .map((file) => file.name)
        .filter((name) => name.startsWith(prefix));

      if (ownFiles.length > 0) {
        const { error: removeError } = await supabaseAdmin.storage
          .from("uploads")
          .remove(ownFiles);
        if (removeError) {
          console.error("uploads remove failed:", removeError.message);
        }
      }
    }

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      userId,
    );
    if (deleteError) {
      return jsonResponse({ error: deleteError.message }, 500);
    }

    return jsonResponse({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unbekannter Fehler";
    return jsonResponse({ error: message }, 500);
  }
});
