<div align="center">

<img src="assets/domspatzen_compact.svg" alt="Chrono Logo" width="72" height="72" />

# Chrono

**Dein persönlicher All-in-One-Kalender für die Regensburger Domspatzen**

Chorplan, Stundenplan, Speiseplan und Events — alles an einem Ort, auf dich zugeschnitten.

<br />

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material-3-6750A4?style=flat-square&logo=material-design&logoColor=white)](https://m3.material.io)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3FCF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![PowerSync](https://img.shields.io/badge/PowerSync-Offline--Sync-111827?style=flat-square)](https://www.powersync.com)

<br />

[Features](#features) · [Screenshots](#screenshots) · [Lokal starten](#lokal-starten) · [Architektur](#architektur) · [Tech-Stack](#tech-stack)

</div>

---

## Über Chrono

Wer bei den **Regensburger Domspatzen** ist, kennt das Problem: Chorplan hier, Stundenplan da, der Speiseplan irgendwo auf einem Aushang, Konzerttermine in einer anderen Mail — und man verliert den Überblick.

**Chrono** bündelt alles in einer App. Keine fünf verschiedenen Nachrichten mehr, kein ständiges Suchen. Du siehst nur, was für *dich* relevant ist — gefiltert nach Chor, Stimme, Klasse, Schulzweig und Ernährung.

---

## Screenshots

> **Platzhalter:** Lege vier App-Store-Screenshots unter [`docs/screenshots/`](docs/screenshots/) ab.  
> Anleitung: [`docs/screenshots/README.md`](docs/screenshots/README.md)

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/screenshots/01-tagesansicht.png" alt="Tagesansicht — Platzhalter" width="280" /><br />
      <sub><b>Tagesansicht</b> — Stundenplan & Termine</sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/screenshots/02-wochenansicht.png" alt="Wochenansicht — Platzhalter" width="280" /><br />
      <sub><b>Wochenansicht</b> — Raster mit farbigen Karten</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <img src="docs/screenshots/03-filter-suche.png" alt="Filter & Suche — Platzhalter" width="280" /><br />
      <sub><b>Filter & Suche</b> — Persönliche Ansicht</sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/screenshots/04-hausaufgaben.png" alt="Hausaufgaben — Platzhalter" width="280" /><br />
      <sub><b>Hausaufgaben</b> — Aufgaben & Familie</sub>
    </td>
  </tr>
</table>

---

## Features

### Kalender

- **Tages- und Wochenansicht** mit farbcodierten Terminkarten
- **Chorpläne**, **Schulstunden**, **Events** und **Speiseplan** in einer Oberfläche
- **Intelligente Filter** nach Chor, Stimme, Klasse, Schulzweig (NTG / Musisch) und Ernährung
- **Kalendersuche** mit eigenem Filter-Overlay
- **Mehrere Schulzweige** gleichzeitig — eigener Zweig hervorgehoben, gleichzeitige Stunden nebeneinander
- **Termindetails** mit Bildern, Ablaufplänen und Notizen
- **Event-Editor** für Administratoren

### Hausaufgaben

- Aufgaben pro Fach anlegen und verwalten
- Verknüpfung mit Schulstunden im Kalender
- **Klassen-Vorschläge** von Mitschülern annehmen oder ablehnen

### Konto & Familie

- Anmeldung per **E-Mail**, **Google** oder **Apple**
- Onboarding mit Profil (Chor, Stimme, Klasse, Schulzweig, Ernährung)
- **Elternmodus**: Kinder verknüpfen und deren Kalender einsehen
- Kindwechsel mit eigenen Kalenderfiltern pro Profil

### Plattform-Integrationen

- **Offline-Sync** über PowerSync — Kalender auch ohne Netz nutzbar
- **Push-Benachrichtigungen** (Firebase Cloud Messaging)
- **Live Activities** (iOS) für laufende Events und Stundenplan
- **Home-Screen-Widget** mit Tagesvorschau
- **Dark Mode** (System, Hell, Dunkel)

### Weitere Details

- Material-3-Design mit angepassten Akzentfarben pro Fach
- Stimmgabel in den Einstellungen
- Haptisches Feedback und flüssige Animationen

---

## Lokal starten

### Voraussetzungen

- [Flutter](https://docs.flutter.dev/get-started/install) ≥ 3.0 (SDK `^3.11`)
- Xcode (iOS) und/oder Android Studio
- Optional: Firebase-Konfiguration für Push-Benachrichtigungen

### Repository klonen

```bash
git clone https://github.com/RiceJuice/chrono.git
cd chrono
flutter pub get
```

### Umgebungsvariablen (optional)

Für eigene Supabase- oder Google-Auth-Keys kopiere die Beispiel-Datei und passe sie an:

```bash
cp config/dart_defines.example.json config/dart_defines.local.json
```

Start mit lokalen Defines:

```bash
flutter run --dart-define-from-file=config/dart_defines.local.json
```

Ohne eigene Datei nutzt die App die in `lib/main.dart` hinterlegten Standardwerte.

### Tests

```bash
flutter test
flutter analyze
```

---

## Architektur

Das Projekt folgt einer **Feature-basierten Clean Architecture**:

```
lib/
├── core/           # Routing, Theme, DB/Sync, Auth, Push, Netzwerk
└── features/
    ├── calendar/   # Kalender, Filter, Suche, Live Activities, Widget
    ├── homework/   # Hausaufgaben
    ├── login/      # Auth, Onboarding, Eltern-Verknüpfung
    └── settings/   # Profil, Darstellung, Familie
```

Jedes Feature ist in **`presentation/`**, **`domain/`** und **`data/`** gegliedert. State Management mit **Riverpod**, Navigation mit **go_router**.

---

## Tech-Stack

| Bereich | Technologie |
|---|---|
| Framework | Flutter · Dart |
| UI | Material 3 · Google Fonts · Phosphor Icons |
| State | Riverpod (+ Codegen) |
| Navigation | go_router |
| Backend & Auth | Supabase |
| Lokale DB & Sync | PowerSync · SQLite |
| Push | Firebase Cloud Messaging |
| iOS Extras | Live Activities · Home Widget |

---

## Screenshots einfügen — Kurzanleitung

1. Vier App-Store-Screenshots exportieren (PNG, idealerweise 1290 × 2796 px).
2. In den Ordner [`docs/screenshots/`](docs/screenshots/) legen:
   - `01-tagesansicht.png`
   - `02-wochenansicht.png`
   - `03-filter-suche.png`
   - `04-hausaufgaben.png`
3. Committen und pushen — die Bilder erscheinen automatisch in dieser README.

Ausführliche Anleitung: [`docs/screenshots/README.md`](docs/screenshots/README.md)

---

## Status

Chrono ist in aktiver Entwicklung. Kernfunktionen (Kalender, Sync, Auth, Hausaufgaben, Elternmodus) sind implementiert; weitere Verbesserungen und Features kommen laufend dazu.

---

<div align="center">

**Gebaut für die Regensburger Domspatzen**

<sub>Flutter · Supabase · PowerSync</sub>

</div>
