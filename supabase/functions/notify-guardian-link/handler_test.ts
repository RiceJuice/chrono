import { handleGuardianNotification } from "./handler.ts";
import type { sendFcmToToken } from "../_shared/fcm_v1.ts";
function equal(actual: unknown, expected: unknown) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}
const generation = "2026-11-27T12:00:00Z";
const request = () =>
  new Request("https://unit.invalid/function", {
    method: "POST",
    headers: { Authorization: "Bearer synthetic-service" },
    body: "{}",
  });
async function scenario(
  options: {
    devices?: string[];
    status?: string;
    old?: boolean;
    error?: boolean;
    accepted?: string[];
  },
  send: typeof sendFcmToToken,
) {
  const fetchBefore = globalThis.fetch;
  const envs = {
    SUPABASE_URL: "https://unit.invalid",
    SUPABASE_SERVICE_ROLE_KEY: "synthetic-service",
    FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify({
      project_id: "test",
      client_email: "test@example.invalid",
      private_key: "synthetic",
    }),
  };
  const previous = Object.fromEntries(
    Object.keys(envs).map((k) => [k, Deno.env.get(k)]),
  );
  for (const [k, v] of Object.entries(envs)) Deno.env.set(k, v);
  const finishes: Record<string, unknown>[] = [];
  const deleted: string[] = [];
  globalThis.fetch = (async (input, init) => {
    const url = new URL(
      typeof input === "string"
        ? input
        : input instanceof URL
        ? input.href
        : input.url,
    );
    const body = typeof init?.body === "string" ? JSON.parse(init.body) : {};
    let result: unknown = null;
    if (url.pathname.endsWith("claim_guardian_notifications")) {
      result = [{
        id: "job",
        link_id: "link",
        action: "request",
        attempts: 1,
        request_generation: options.old ? "old" : generation,
      }];
    } else if (url.pathname.endsWith("guardian_child_links")) {
      result = {
        id: "link",
        guardian_id: "parent",
        child_id: "child",
        status: options.status ?? "pending",
        requested_at: generation,
        guardian_first_name: "Alex",
        guardian_last_name: "Beispiel",
      };
    } else if (url.pathname.endsWith("profile_push_devices")) {
      if (init?.method === "DELETE") deleted.push(url.search);
      else if (options.error) {
        return new Response('{"message":"temporary"}', {
          status: 503,
          headers: { "Content-Type": "application/json" },
        });
      } else {result = (options.devices ?? []).map((id) => ({
          id,
          user_id: "child",
          fcm_token: id,
        })
        );}
    } else if (url.pathname.endsWith("guardian_notification_device_accepted")) {
      result = (options.accepted ?? []).includes(body.p_device);
    } else if (url.pathname.endsWith("finish_guardian_notification")) {
      finishes.push(body);
    } else if (!url.pathname.endsWith("record_guardian_notification_device")) {
      throw new Error(`Unexpected request ${url.pathname}`);
    }
    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    });
  }) as typeof fetch;
  try {
    return {
      body: await (await handleGuardianNotification(request(), send)).json(),
      finishes,
      deleted,
    };
  } finally {
    globalThis.fetch = fetchBefore;
    for (const k of Object.keys(envs)) {
      const v = previous[k];
      if (v === undefined) Deno.env.delete(k);
      else Deno.env.set(k, v);
    }
  }
}
Deno.test("no token remains queued and is not reported accepted", async () => {
  const result = await scenario({}, () => {
    throw new Error("must not send");
  });
  equal(result.body.accepted, 0);
  equal(result.body.no_devices, 1);
  equal(result.finishes[0].p_retry, true);
});
Deno.test("partial acceptance and token cleanup preserve rotated tokens", async () => {
  const result = await scenario(
    { devices: ["valid", "expired"] },
    async (_a, token, _title, body) => {
      if (!body.includes("Prüfe die Anfrage in Chrono")) {
        throw new Error(
          "Unexpected message",
        );
      }
      return token === "valid"
        ? { ok: true }
        : { ok: false, errorCode: "UNREGISTERED" };
    },
  );
  equal(result.body.accepted, 1);
  equal(result.body.failed, 1);
  equal(result.finishes[0].p_retry, true);
  equal(result.deleted.length, 1);
  if (!result.deleted[0].includes("fcm_token=eq.expired")) {
    throw new Error("Rotation not guarded");
  }
});
Deno.test("retry skips devices whose message was already accepted", async () => {
  let calls = 0;
  const result = await scenario(
    { devices: ["valid"], accepted: ["valid"] },
    async () => {
      calls++;
      return { ok: true };
    },
  );
  equal(calls, 0);
  equal(result.body.accepted, 1);
  equal(result.finishes[0].p_retry, false);
});
Deno.test("revoked and older request generations are discarded", async () => {
  for (const opts of [{ status: "revoked" }, { old: true }]) {
    const result = await scenario(opts, () => {
      throw new Error("must not send");
    });
    equal(result.body.accepted, 0);
    equal(result.finishes[0].p_retry, false);
  }
});
Deno.test("lookup failure is distinct from no devices", async () => {
  const result = await scenario({ error: true }, () => {
    throw new Error("must not send");
  });
  equal(result.body.failed, 1);
  equal(result.body.no_devices, 0);
  equal(result.finishes[0].p_retry, true);
});
