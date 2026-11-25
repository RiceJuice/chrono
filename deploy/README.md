# Chrono verteilen

## Android (APK)

`chrono.apk` an das Handy schicken (z. B. per WhatsApp, Mail, Google Drive) →
auf dem Handy antippen → „Aus dieser Quelle installieren“ erlauben → Installieren.

Bauen:

```bash
flutter build apk --release
# Ergebnis: build/app/outputs/flutter-apk/app-release.apk
```

Ohne `android/key.properties` wird die APK mit dem lokalen Debug-Schlüssel signiert.
Updates lassen sich nur über eine App mit **derselben** Signatur installieren –
sonst vorher deinstallieren.

## Web / iPhone (PWA)

Bauen:

```bash
dart run powersync:setup_web   # einmalig: lädt sqlite3.wasm + powersync_db.worker.js nach web/
flutter build web --release
# Ergebnis: build/web/
```

Auf dem iPhone: Seite in **Safari** öffnen → Teilen-Symbol → **„Zum Home-Bildschirm“**.
Wichtig: Die Seite muss über **HTTPS** laufen (sonst funktionieren lokale Datenbank
und Anmeldung im Browser nicht).

### Variante 1 – Netlify Drop (am einfachsten, kostenlos, HTTPS inklusive)

1. <https://app.netlify.com/drop> öffnen und (kostenlos) anmelden, z. B. mit GitHub.
2. Den Ordner `build/web` (bzw. den entpackten Ordner aus `chrono-web.zip`) per
   Drag & Drop auf die Seite ziehen.
3. Fertig – Netlify zeigt eine Adresse wie `https://irgendwas.netlify.app`.
   Unter *Site configuration → Change site name* lässt sie sich umbenennen.

Alternativ genauso einfach: Cloudflare Pages („Upload assets“).

### Variante 2 – Homeserver mit Docker

Auf den Server kopieren:

```
chrono-web/
  docker-compose.yml   (aus deploy/web/)
  nginx.conf           (aus deploy/web/)
  site/                (Inhalt von build/web)
```

```bash
cd chrono-web
docker compose up -d
```

In Portainer: *Stacks → Add stack → Web editor*, Inhalt von `docker-compose.yml`
einfügen und die beiden Pfade (`./site`, `./nginx.conf`) auf absolute Pfade auf dem
Server ändern.

Die App läuft dann auf `http://<server-ip>:8080`. Für das iPhone braucht es HTTPS
über einen Reverse-Proxy davor, z. B. Nginx Proxy Manager, Caddy, Traefik oder
einen Cloudflare Tunnel (`cloudflared`), der zusätzlich den Zugriff von außen
ohne Portfreigabe ermöglicht.
