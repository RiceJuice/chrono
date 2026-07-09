/**
 * FCM HTTP v1 (OAuth2 service account → messages:send).
 */

import * as jose from "npm:jose@5.9.6";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FCM_SEND_URL =
  "https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

export type FirebaseServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function fetchAccessToken(
  serviceAccount: FirebaseServiceAccount,
): Promise<string> {
  const now = Date.now();
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60_000) {
    return cachedAccessToken.token;
  }

  const pem = serviceAccount.private_key.replace(/\\n/g, "\n");
  const key = await jose.importPKCS8(pem, "RS256");
  const jwt = await new jose.SignJWT({ scope: FCM_SCOPE })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience(TOKEN_URL)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(key);

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`FCM OAuth failed (${res.status}): ${text}`);
  }

  const json = (await res.json()) as { access_token: string; expires_in: number };
  cachedAccessToken = {
    token: json.access_token,
    expiresAt: now + json.expires_in * 1000,
  };
  return json.access_token;
}

export type FcmSendResult = {
  ok: boolean;
  errorCode?: string;
  errorMessage?: string;
};

export async function sendFcmToToken(
  serviceAccount: FirebaseServiceAccount,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<FcmSendResult> {
  const accessToken = await fetchAccessToken(serviceAccount);
  const url = FCM_SEND_URL.replace("{projectId}", serviceAccount.project_id);

  const message: Record<string, unknown> = {
    token,
    notification: { title, body },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
    android: {
      notification: {
        sound: "default",
      },
    },
  };
  if (data && Object.keys(data).length > 0) {
    message.data = data;
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message }),
  });

  if (res.ok) {
    return { ok: true };
  }

  const errBody = (await res.json().catch(() => ({}))) as {
    error?: { message?: string; status?: string; details?: Array<{ errorCode?: string }> };
  };
  const details = errBody.error?.details ?? [];
  const errorCode = details.find((d) => d.errorCode)?.errorCode ??
    errBody.error?.status;
  return {
    ok: false,
    errorCode,
    errorMessage: errBody.error?.message ?? await res.text(),
  };
}

export type LiveActivityFcmEvent = "start" | "update" | "end";

export type LiveActivityFcmPayload = {
  token: string;
  platform: string;
  event: LiveActivityFcmEvent;
  activityId: string;
  contentState: Record<string, string | number | boolean>;
  liveActivityPushToken?: string | null;
  pushToStartToken?: string | null;
  eventId: string;
  activityType?: string;
  dayDate?: string;
};

export async function sendLiveActivityFcm(
  serviceAccount: FirebaseServiceAccount,
  payload: LiveActivityFcmPayload,
): Promise<FcmSendResult> {
  const accessToken = await fetchAccessToken(serviceAccount);
  const url = FCM_SEND_URL.replace("{projectId}", serviceAccount.project_id);
  const nowMs = Date.now();
  const nowSec = Math.floor(nowMs / 1000);

  const activityType = payload.activityType ?? "schedule_live_activity";
  const data: Record<string, string> = {
    timestamp: String(nowMs),
    event: payload.event,
    "activity-id": payload.activityId,
    activity_id: payload.activityId,
    type: activityType,
    event_id: payload.eventId,
  };
  if (payload.dayDate) {
    data.day_date = payload.dayDate;
  }
  // Auf iOS steckt der komplette Content-State bereits (unkomprimiert) in
  // aps["content-state"] - das ist der einzige Ort, den ActivityKit fuer die
  // Live-Activity-Aktualisierung tatsaechlich liest. Ihn zusaetzlich als
  // JSON-String in `data` zu duplizieren hat bei einem vollen Stundenplan
  // (mehrere Segmente inkl. Titel/Farben) die harte FCM-Groessengrenze von
  // 4096 Bytes gerissen ("Message is too large") - der Push wurde dann fuer
  // JEDEN Update/End-Versuch abgelehnt. Auf Android hingegen wird genau
  // dieses `data["content-state"]`-Feld vom nativen Handler ausgewertet, dort
  // bleibt es also zwingend erforderlich.
  if (payload.platform !== "ios") {
    data["content-state"] = JSON.stringify(payload.contentState);
  }

  const message: Record<string, unknown> = {
    token: payload.token,
    data,
    android: { priority: "high" },
  };

  if (payload.platform === "ios") {
    const aps: Record<string, unknown> = {
      timestamp: nowSec,
      event: payload.event,
      "content-state": payload.contentState,
      "attributes-type": "LiveActivitiesAppAttributes",
      attributes: {},
    };
    if (payload.event === "end") {
      aps["dismissal-date"] = nowSec;
    }

    const apns: Record<string, unknown> = {
      headers: { "apns-priority": "10" },
      payload: { aps },
    };

    const liveToken = payload.event === "start"
      ? payload.pushToStartToken
      : payload.liveActivityPushToken;
    if (liveToken && liveToken.trim().length > 0) {
      apns.live_activity_token = liveToken.trim();
    }

    message.apns = apns;
  } else {
    message.notification = {
      title: String(
        payload.contentState.currentTitle ??
          (activityType === "timetable_live_activity" ? "Stundenplan" : "Ablaufplan"),
      ),
      body: String(payload.contentState.currentSubtitle ?? ""),
    };
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ message }),
  });

  if (res.ok) {
    return { ok: true };
  }

  const errBody = (await res.json().catch(() => ({}))) as {
    error?: { message?: string; status?: string; details?: Array<{ errorCode?: string }> };
  };
  const details = errBody.error?.details ?? [];
  const errorCode = details.find((d) => d.errorCode)?.errorCode ??
    errBody.error?.status;
  return {
    ok: false,
    errorCode,
    errorMessage: errBody.error?.message ?? await res.text(),
  };
}

export function parseServiceAccountJson(raw: string): FirebaseServiceAccount {
  const parsed = JSON.parse(raw) as FirebaseServiceAccount;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT_JSON");
  }
  return parsed;
}

export function isUnregisteredTokenError(errorCode?: string): boolean {
  // "INVALID_ARGUMENT" bewusst NICHT hier: dieser Code kommt von FCM auch bei
  // einem strukturell fehlerhaften Payload (z. B. fehlendes
  // apns.live_activity_token bei einer Live-Activity-Push), NICHT nur bei
  // einem toten fcm_token. Ihn hier zu behandeln hat wiederholt gesunde,
  // frisch registrierte Geraete geloescht, bevor die App
  // push_to_start_token/live_activity_push_token nachliefern konnte - siehe
  // sendLiveActivityToDevice(), das genau deshalb jetzt vorher prueft, ob der
  // fuer den jeweiligen Event-Typ benoetigte Token ueberhaupt vorhanden ist.
  return errorCode === "UNREGISTERED" || errorCode === "NOT_FOUND";
}
