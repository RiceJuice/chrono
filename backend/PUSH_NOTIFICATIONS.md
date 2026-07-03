# Push-Benachrichtigungen

Zwei Kanäle:

1. **Admin (n8n):** n8n-Workflow → `notify-admins` → FCM → alle Admin-Geräte
2. **Termin-Bearbeitung (App):** Admin speichert Termin → optional Broadcast-Dialog → `notify-event-change` → FCM → betroffene Nutzer

## Architektur

1. **Flutter (alle Nutzer):** FCM-Token pro Gerät/Installation in `profile_push_devices` (Upsert).
2. **n8n:** HTTP-POST an `notify-admins` mit Webhook-Secret.
3. **Edge Function `notify-admins`:** Alle Zeilen für Admins (`profiles.role = Admin`), **jedes Gerät** bekommt eine FCM-Nachricht.
4. **Edge Function `notify-event-change`:** Authentifizierter Admin ruft nach Termin-Bearbeitung auf; Zielgruppe wird serverseitig aus Profil-Daten gematcht.

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
2. APNs-**Authentifizierungsschlüssel** (.p8) in Firebase → Cloud Messaging → Apple hochladen (nicht nur „Development Certificate“).
3. Xcode Cloud / **TestFlight**-Build installieren — [`ios/ci_scripts/ci_post_clone.sh`](../ios/ci_scripts/ci_post_clone.sh) unverändert.

`Info.plist` enthält bereits `UIBackgroundModes` → `remote-notification`.

#### TestFlight vs. „Development“-APNs-Key

| Begriff | Bedeutung |
|---------|-----------|
| **APNs Auth Key (.p8)** in Apple Developer | Ein Schlüssel gilt für **Sandbox und Production** — in Firebase unter „APNs Authentication Key“ hochladen. |
| **TestFlight / App Store Build** | App braucht `aps-environment` = **`production`** → [`RunnerRelease.entitlements`](../ios/Runner/RunnerRelease.entitlements) (Xcode Cloud Archive = Release). |
| **Nur Xcode-Debug direkt aufs Gerät** | `development` → [`RunnerDebug.entitlements`](../ios/Runner/RunnerDebug.entitlements) |

**Wichtig:** TestFlight nutzt **production**-Entitlements in der App, auch wenn du in Apple einen Key „für Development“ erstellt hast. Der .p8-Key in Firebase muss trotzdem hinterlegt sein.

`THIRD_PARTY_AUTH_ERROR` auf iOS = APNs in Firebase fehlt/falsch oder .p8/Key-ID/Team-ID stimmen nicht.

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

Tabelle: `profile_push_devices` (Migration `*_profile_push_devices.sql`). Legacy-Spalten `profiles.fcm_token` werden von der App nicht mehr beschrieben.

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
supabase functions deploy notify-event-change
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

Erwartete Antwort: `{"sent":1,"failed":0,"device_count":1,"admin_count":1,...}` (`sent` = erfolgreiche FCM-Sends, kann > Admins sein bei mehreren Geräten).

## 7. App-Verifikation

1. Als **beliebiger Nutzer** anmelden, App auf **physischem Gerät** (Emulator oft ohne Push) — Token in `profile_push_devices`?
2. Als **Admin** Termin bearbeiten → Dialog „Änderung mitteilen?“ → „Ja, benachrichtigen“ → Push auf betroffenen Geräten.
3. n8n/curl-Test für `notify-admins` → Push auf Admin-Geräten.

### Termin-Broadcast (`notify-event-change`)

- **Aufruf:** Flutter `EventBroadcastService` nach Speichern im Termin-Editor (JWT des Admins).
- **Zielgruppe:** Chor, Stimmen, Schulzweig, Klasse, Ernährung (bei Essen) — Matching gegen `profiles`.
- **Zwei Nachrichten bei Zielgruppen-Wechsel:**
  - Alte Zielgruppe (nur noch alt, nicht neu): „Termin entfernt: …“
  - Neue Zielgruppe: „Termin geändert: …“ mit Feldänderungen
- **FCM data:** `{ "type": "event_change", "event_id": "…" }`

Deploy (zusätzlich zu Abschnitt 4):

```bash
supabase functions deploy notify-event-change
```

`verify_jwt = true` — nur authentifizierte Admins.

## 10. Ablaufplan Live Activities (`schedule-live-activity`)

**Auslöser (bedarfsgesteuert, kein Minuten-Polling):**
- **Geplante Einmal-Jobs** (`event_live_activity_jobs` + pg_cron) → `start` / `end` exakt zu Termin- oder Segmentzeit — nur für `calendar_events` mit `type = 'event'`
- **DB-Trigger** auf `calendar_events` (INSERT/UPDATE/DELETE) und `event_schedules` (INSERT/UPDATE/DELETE) → Job-Neuplanung + sofortiger FCM `update`/`end` bei laufender Live Activity

**Termine ohne Ablaufplan:** Eine Live Activity von `start_time` bis `end_time` (Titel = `event_name`).

**Zielgruppe:** Nur Geräte, deren Profil zu `choir`/`voices` des Events passt.

**Lokal in der App:** `flutter_local_notifications` + Einmal-Timer planen Segment-/Terminstarts und Tagesende; Coordinator startet/beendet die Activity über `live_activities`. FCM `update` aktualisiert Inhalte (Titel, Zeiten, Zielgruppe).

### Deploy

```bash
supabase db push
supabase functions deploy schedule-live-activity --no-verify-jwt
```

Migration `*_event_live_activity_on_demand.sql` legt Job-Tabelle, Sync-Funktion und Postgres-Trigger an (Vault-Secret muss gesetzt sein).

### Secrets

```bash
# 1) Edge Function Secret (CLI)
supabase secrets set SCHEDULE_LIVE_ACTIVITY_CRON_SECRET="<generierter-hex-string>"
```

**2) Postgres/pg_cron:** `ALTER DATABASE SET` ist auf Supabase Hosted **nicht erlaubt**.  
Stattdessen Secret im **Vault** speichern — SQL Editor:

```sql
SELECT vault.create_secret(
  '<derselbe-hex-string>',
  'schedule_live_activity_cron_secret',
  'Cron secret für schedule-live-activity'
);
```

Falls die Migration schon ohne Vault lief: komplettes Setup-Skript  
[`backend/SCHEDULE_LIVE_ACTIVITY_CRON_SETUP.sql`](SCHEDULE_LIVE_ACTIVITY_CRON_SETUP.sql) im SQL Editor ausführen (Secret-Wert anpassen).

Der pg_cron-Job für Minuten-Polling ist entfernt. Geplante Dispatches lesen das Secret aus `vault.decrypted_secrets`.

### Test (curl)

```bash
curl -X POST "https://chrbvfaknykaycwumuba.supabase.co/functions/v1/schedule-live-activity" \
  -H "Content-Type: application/json" \
  -H "x-cron-secret: <SCHEDULE_LIVE_ACTIVITY_CRON_SECRET>" \
  -d '{"mode":"dispatch","event_id":"<uuid>","action":"start"}'
```

Erwartung: `{"processed":1,"sent":…,"mode":"dispatch",…}` oder `skipped` wenn kein passendes Event/Gerät.

Ohne gültigen `mode`: HTTP `400`. Ohne Secret: HTTP `401`.

### iOS

- Widget Extension `ChronoWidgetExtension` in Xcode (bereits im Repo)
- App Group: `group.com.domspatzen.chronoapp`
- Push-to-Start-/Activity-Tokens in `profile_push_devices`

### Android

- `ChronoLiveActivityManager` + `res/layout/live_activity.xml`

## 8. Troubleshooting

| Symptom | Ursache / Fix |
|---------|----------------|
| `sent: 0`, `skipped: N` (notify-admins) | Keine Admins mit Token — App als Admin öffnen, Berechtigung erlauben |
| `sent: 0` (notify-event-change) | Keine betroffenen Nutzer mit Token oder Zielgruppe leer — Profil-Zuordnung prüfen |
| 403 Forbidden (notify-event-change) | Aufrufer ist kein Admin |
| 401 Unauthorized | `x-webhook-secret` falsch oder Secret nicht gesetzt |
| FCM 401 / 403 | `FIREBASE_SERVICE_ACCOUNT_JSON` ungültig oder falsches Firebase-Projekt |
| `PERMISSION_DENIED` + `cloudmessaging.messages.create` | FCM API in Google Cloud aktivieren + Rolle **Firebase Cloud Messaging Admin** |
| `failures` + Emulator | Push nur auf **physischem** iPhone/Android testen |
| `THIRD_PARTY_AUTH_ERROR` (iOS) | APNs **Authentication Key** (.p8) in Firebase; TestFlight = `production`-Entitlements |
| iOS keine Push | App-ID Push aktiv; neuer Build nach Entitlements; kein Simulator |
| Push ohne Ton | iPhone: Stumm-Schalter/Fokus; Einstellungen → Chrono → Töne; FCM sendet `sound: default` (Edge Function) |
| Android API 33+ | `POST_NOTIFICATIONS` in Manifest; Nutzer muss erlauben |
| Token verschwindet | Edge Function löscht ungültige Tokens (`UNREGISTERED`) — App neu öffnen |

## 9. Sicherheit

- `service_role` und Firebase-JSON nur in Supabase Secrets.
- `notify-admins`: Webhook nur über `x-webhook-secret` (`verify_jwt = false` für n8n).
- `notify-event-change`: JWT-Pflicht + Admin-Rollen-Check in der Function.
- RLS auf `profile_push_devices`: Nutzer sehen/ändern nur eigene Geräte (`user_id = auth.uid()`).

## Mehrere Geräte pro Nutzer

Tabelle `profile_push_devices`: ein Eintrag pro **Installation** (`device_id` in SharedPreferences).

- iPhone + iPad = zwei Zeilen → beide erhalten Push.
- Logout löscht nur das **aktuelle** Gerät.
- Ungültige FCM-Tokens: Edge Function löscht die betroffene Zeile (`UNREGISTERED`).
