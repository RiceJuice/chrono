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

export function parseServiceAccountJson(raw: string): FirebaseServiceAccount {
  const parsed = JSON.parse(raw) as FirebaseServiceAccount;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT_JSON");
  }
  return parsed;
}

export function isUnregisteredTokenError(errorCode?: string): boolean {
  return errorCode === "UNREGISTERED" ||
    errorCode === "INVALID_ARGUMENT" ||
    errorCode === "NOT_FOUND";
}
