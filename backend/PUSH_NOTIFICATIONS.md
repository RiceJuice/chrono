# Admin Push-Benachrichtigungen

n8n-Workflow → Supabase Edge Function `notify-admins` → FCM → alle Admins mit gespeichertem `profiles.fcm_token`.

## Architektur

1. **Flutter (nur Admin):** Nach Login Berechtigung anfragen, FCM-Token holen, in `profiles` speichern.
2. **n8n:** Am Ende des Workflows HTTP-POST an `notify-admins` mit Webhook-Secret.
3. **Edge Function:** Lädt alle `profiles` mit `role = 'Admin'` und gültigem Token, sendet FCM HTTP v1.

SQL-Referenz: [`PUSH_NOTIFICATIONS.sql`](PUSH_NOTIFICATIONS.sql)  
Migration: [`supabase/migrations/`](../supabase/migrations/)

## 1. Firebase einrichten (einmalig)

1. [Firebase Console](https://console.firebase.google.com) → Projekt anlegen (z. B. `chronoapp`).
2. **Android:** App `com.domspatzen.chronoapp` → `google-services.json` nach `android/app/`.
3. **iOS:** Bundle-ID aus Xcode → `GoogleService-Info.plist` nach `ios/Runner/`.
4. **Cloud Messaging** aktivieren; iOS: APNs-Authentifizierungsschlüssel (.p8) in Firebase hochladen.
5. **Dienstkonto:** Projekteinstellungen → Dienstkonten → neuen privaten Schlüssel (JSON) — **nur** als Supabase Secret, nie ins Git.

### iOS Push ohne Mac (Xcode Cloud)

Im Repo bereits eingerichtet:

| Datei | `aps-environment` | Build |
|-------|-------------------|--------|
| [`ios/Runner/RunnerDebug.entitlements`](../ios/Runner/RunnerDebug.entitlements) | `development` | Debug |
| [`ios/Runner/RunnerRelease.entitlements`](../ios/Runner/RunnerRelease.entitlements) | `production` | Release, Profile, Xcode Cloud Archive |

Zusätzlich **ohne Xcode am Mac**:

1. [Apple Developer](https://developer.apple.com/account) → Identifiers → `com.domspatzen.chronoapp` → **Push Notifications** aktivieren.
2. APNs-Key (.p8) in Firebase → Cloud Messaging → Apple hochladen.
3. Xcode Cloud Build installieren (TestFlight/Ad-hoc) — [`ios/ci_scripts/ci_post_clone.sh`](../ios/ci_scripts/ci_post_clone.sh) bleibt unverändert; Entitlements kommen aus `project.pbxproj`.

`Info.plist` enthält bereits `UIBackgroundModes` → `remote-notification`.

### FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<dein-firebase-project-id>
```

Ersetzt [`lib/firebase_options.dart`](../lib/firebase_options.dart). Ohne diesen Schritt startet Firebase nicht korrekt.

## 2. Supabase: Migration

```bash
supabase db push
# oder Migration aus supabase/migrations manuell im Dashboard ausführen
```

Spalten: `profiles.fcm_token`, `profiles.fcm_token_updated_at`.

Admin-Rolle setzen (falls noch nicht):

```sql
UPDATE profiles SET role = 'Admin' WHERE id = '<user-uuid>';
```

## 3. `N8N_WEBHOOK_SECRET` erzeugen & lokal speichern

Du erfindest den Wert selbst (kein Firebase, kein n8n-Vorgabe-Token).

**PowerShell (empfohlen, Windows):**

```powershell
-join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
```

Alternativ mit OpenSSL, falls installiert: `openssl rand -hex 32`

**Lokal auf diesem PC (gitignored):**

1. Datei [`config/push_secrets.local.env`](../config/push_secrets.local.env) (Vorlage: [`push_secrets.local.env.example`](../config/push_secrets.local.env.example))
2. Zeile eintragen: `N8N_WEBHOOK_SECRET=<dein-generierter-string>`
3. Datei wird **nicht** committed (steht in `.gitignore`)

**Wichtig:** Dieselbe Zeichenkette muss **zusätzlich** in Supabase und in n8n stehen (siehe unten). Die lokale `.env` ist nur deine Referenz für curl/n8n — die Edge Function liest Supabase Secrets, nicht diese Datei.

## 4. Supabase Secrets & Deploy

```bash
supabase link --project-ref chrbvfaknykaycwumuba

supabase secrets set N8N_WEBHOOK_SECRET="<derselbe-wert-wie-in-push_secrets.local.env>"

# Komplette Firebase Service-Account-JSON als eine Zeile
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

supabase functions deploy notify-admins --no-verify-jwt
```

`SUPABASE_SERVICE_ROLE_KEY` wird von Supabase in Edge Functions automatisch injiziert.

### Service Account: IAM-Rollen

Für FCM HTTP v1 reicht oft **Firebase-Administrator** nicht aus, wenn die API deaktiviert ist.

1. [Firebase Cloud Messaging API aktivieren](https://console.cloud.google.com/apis/library/fcm.googleapis.com?project=chronoapp-e0ccf)
2. IAM → Dienstaccount aus der JSON → zusätzlich **Firebase Cloud Messaging Admin** (`roles/firebasemessaging.admin`)

Bei `PERMISSION_DENIED` / `cloudmessaging.messages.create` in `failures`: API + diese Rolle prüfen (nicht nur „Ersteller von Dienstkonto-Tokens“).

## 5. n8n HTTP Request Node

| Feld | Wert |
|------|------|
| Method | POST |
| URL | `https://chrbvfaknykaycwumuba.supabase.co/functions/v1/notify-admins` |
| Header `Content-Type` | `application/json` |
| Header `x-webhook-secret` | gleicher Wert wie `N8N_WEBHOOK_SECRET` |

Body (Beispiel):

```json
{
  "title": "Kalender-Import fertig",
  "body": "Der n8n-Workflow wurde erfolgreich abgeschlossen.",
  "data": {
    "type": "calendar_import_complete"
  }
}
```

`data`-Werte müssen Strings sein (FCM-Anforderung).

## 6. Test (curl)

```bash
curl -X POST "https://chrbvfaknykaycwumuba.supabase.co/functions/v1/notify-admins" \
  -H "Content-Type: application/json" \
  -H "x-webhook-secret: <N8N_WEBHOOK_SECRET>" \
  -d '{"title":"Test","body":"Push-Test von curl"}'
```

Erwartete Antwort: `{"sent":1,"failed":0,"skipped":0,...}` (Zahlen je nach Admins).

## 7. App-Verifikation

1. Als Admin anmelden, App auf **physischem Gerät** (Emulator oft ohne Push).
2. In Supabase Table Editor: `profiles.fcm_token` für deine User-ID gesetzt?
3. n8n/curl-Test → Push auf dem Gerät.

## 8. Troubleshooting

| Symptom | Ursache / Fix |
|---------|----------------|
| `sent: 0`, `skipped: N` | Keine Admins mit Token — App als Admin öffnen, Berechtigung erlauben |
| 401 Unauthorized | `x-webhook-secret` falsch oder Secret nicht gesetzt |
| FCM 401 / 403 | `FIREBASE_SERVICE_ACCOUNT_JSON` ungültig oder falsches Firebase-Projekt |
| `PERMISSION_DENIED` + `cloudmessaging.messages.create` | FCM API in Google Cloud aktivieren + Rolle **Firebase Cloud Messaging Admin** |
| `failures` + Emulator | Push nur auf **physischem** iPhone/Android testen |
| iOS keine Push | APNs-Key in Firebase; App-ID Push aktiv; Release-Build = `production`-Entitlements |
| Android API 33+ | `POST_NOTIFICATIONS` in Manifest; Nutzer muss erlauben |
| Token verschwindet | Edge Function löscht ungültige Tokens (`UNREGISTERED`) — App neu öffnen |

## 9. Sicherheit

- `service_role` und Firebase-JSON nur in Supabase Secrets.
- Webhook nur über `x-webhook-secret` absichern (`verify_jwt = false` für n8n).
- Andere Nutzer können fremde `fcm_token` nicht lesen (RLS `profiles_select_own`).

## Hinweis Mehrgeräte

Aktuell ein Token pro Profil (`profiles.fcm_token`). Letztes angemeldetes Gerät gewinnt. Für mehrere Geräte pro Admin später Tabelle `profile_push_devices` erwägen.
