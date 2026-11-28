# Eltern-Kind-Verknüpfung: Umsetzung und Rollout

Stand: 28.11.2026. Arbeitsbasis: `origin/main` bei `fe647dc`. Änderungen liegen auf `codex/guardian-link-completion` im separaten Worktree `chrono-guardian`. Keine produktiven Migrationen, Functions oder Sync-Regeln wurden durch diesen Auftrag ausgerollt. Keine echten Nutzer wurden angeschrieben oder verknüpft.

## Rechte und Datenvertrag

`20261127215040_guardian_link_security.sql` ersetzt die breite Profilsuche durch eine authentifizierte Namenssuche (mindestens drei Zeichen, maximal zehn Treffer, 30 Aufrufe pro Minute). Der alte ungefilterte Such-RPC und sämtliche vorhandenen Overloads zum Ändern fremder Kalenderprofile werden für Clients gesperrt. Admin-Suchrechte bleiben auf den bisherigen Bereich fertig eingerichteter Schüler-/Adminprofile begrenzt. Eigene Profilfelder bleiben editierbar; eine Rolle darf initial im Onboarding gewählt, danach nicht vom Client geändert oder zu Admin hochgestuft werden. Die Fallback-Anlage eines eigenen Profils mit ID und Namen bleibt erlaubt.

Links werden ausschließlich über autorisierte RPCs geändert. Das Kind bestätigt oder lehnt eigene Pending-Anfragen ab. Beide Teilnehmer können pending/confirmed widerrufen. Nur das Kind ändert Freigaben bestätigter Links. Versionskonflikte liefern einen Fehler; identische wiederholte Antworten sind idempotent. IDs und Teilnehmer sind unveränderlich. Wiederanfragen sind frühestens sieben Tage nach Ablehnung/Widerruf zulässig und setzen alle Freigaben zurück. Pro Elternteil sind zehn Anfrageoperationen pro Tag mit jeweils maximal fünf Kindern möglich. Erinnerungen werden unter Zeilensperre frühestens nach 24 Stunden reserviert.

Die vier Freigaben steuern die jeweiligen persönlichen Profilselektoren sowie Aufgaben-/Schulterminzugriff. `guardian_child_links` enthält die minimalen Namen der Teilnehmer und nur die freigegebenen persönlichen Kalenderselektoren. Trigger aktualisieren diese Projektion bei Änderungen und entfernen entzogene Felder. Eltern erhalten keine vollständigen Kinderprofile mehr. Die bisherige Kopie von Schuldaten ins Elternprofil wird auf die Schulfreigabe beschränkt und bei Entzug geleert. Event-Push-Ziele werden aus bestätigten Links und passender Freigabe berechnet. Allgemeine Kalender-/Speiseplandaten bleiben allgemeine Daten.

## Client und Offline-Verhalten

Der Client liest vollständige Server-Snapshots bei Start, Resume, manuellem Aktualisieren und während aktiver Beobachtung alle 30 Sekunden. Revisionen ersetzen Status-Rangfolgen; false und null ersetzen frühere Freigaben und personenbezogene Felder. Ein erfolgreich leerer Bestand entfernt alte Links. Netzwerkfehler sind keine leere Erfolgsliste.

Server-Snapshots werden getrennt nach Nutzer im vorhandenen SharedPreferences-Mechanismus gespeichert. Bekannte Entzüge bleiben damit nach einem Neustart wirksam, auch wenn PowerSync noch hinterherhinkt. Neuere eingehende PowerSync-Revisionen können den Cache ebenfalls einschränken. Die Darstellung verwendet ausschließlich die freigabebegrenzte Link-Projektion. Die Entfernung des alten breiten Profil-Streams bereinigt dessen lokale Zeilen beim nächsten erfolgreichen PowerSync-Abgleich. Bereits angezeigte Daten sind nicht rückwirkend zurückholbar; ein vollständig offline gebliebenes Gerät kann einen noch unbekannten Widerruf nicht erkennen.

Anfrage-Sheets öffnen nur nach bewusstem Einstieg über Banner/Einstellungen oder angetippte Push-Nachricht. Hintergrund-Sync erzwingt keinen Dialog. Die gesamte Verarbeitung ist vor dem ersten await gesperrt. Sitzungswechsel verwerfen alte Ergebnisse und schließen die Anfrageansicht. „Später“ löst keine automatische Wiederöffnung aus. Das Sheet speichert vor dem Schließen; Fehler behalten die Auswahl. Der Elternfluss bleibt auf der tatsächlich gerouteten Kinderauswahl. Die ungenutzte doppelte Warteseite wurde entfernt; der bisherige Route-Alias bleibt erhalten. Die Benachrichtigungseinführung nach der Kinderbestätigung bleibt im Onboarding.

## Outbox und Versand

Eine transaktionale Outbox trennt gespeicherte Anfragen/Antworten vom Push-Versand. `notify-guardian-link` verarbeitet ausschließlich reservierte Jobs. Der Client kann keine neue Nachricht durch bloßes Wiederholen des Function-Aufrufs erzeugen. Eine neue Erinnerung muss vorher den serverseitigen Reminder-RPC passieren.

Jobs haben höchstens drei Versuche, Backoff von fünf bzw. zehn Minuten und eine fünfminütige Lease für abgestürzte Worker. Bereits von FCM angenommene Geräte werden für diesen Job gespeichert und beim Retry übersprungen. Ungültige Tokens werden nur entfernt, wenn der Token seit dem Lesen unverändert ist. Fehlende Geräte, Fehler und Teilversand werden getrennt erfasst. `accepted` bedeutet Annahme durch FCM, keine nachgewiesene Anzeige auf dem Gerät. Beim Absturz zwischen FCM-Annahme und Speicherung der Bestätigung ist eine doppelte Zustellung prinzipiell möglich; Exactly-once-Zustellung wird nicht zugesichert.

`supabase/ops/guardian_link_worker_schedule.sql` richtet den minütlichen Worker und die Bereinigung abgeschlossener Jobs nach 30 Tagen ein. Vor Ausführung müssen `pg_cron`, `pg_net` und zwei Vault-Secrets vorhanden sein: `guardian_link_worker_url` (vollständige Function-URL) und `guardian_link_worker_service_key` (Service-Role-JWT). Ohne diesen Scheduler ist die Outbox zwar dauerhaft, aber ein vom Client unabhängiger Retry noch nicht aktiv. Schlüssel gehören ausschließlich in Vault, niemals in Dateien oder den Client.

## Bestandsverträglichkeit und produktiver Abgleich

Lesend verifiziert wurde Projekt `chrbvfaknykaycwumuba` / Chrono. Die aktiven breiten Profilpolicies, direkten Link-Updates, Legacy-RPCs und der abweichende produktive Schulprofil-Trigger wurden geprüft. Die aktive `notify-guardian-link` wurde abgerufen. Die Migration ergänzt Revision, Änderungs-/Anfragezeit und begrenzte Identitätsfelder; bestehende Status/Freigaben bleiben erhalten. Ein Backfill aktualisiert Projektionen ohne historische Benachrichtigungen nachzusenden. Der zusätzliche Aufruf der vorhandenen Schulprofil-Synchronisation bleibt idempotent. Bestehende Pending-Anfragen erhalten beim Backfill einen konservativen neuen Erinnerungszeitraum.

`public.school_assessments` fehlt weiterhin im aktiven Projekt, obwohl die lokalen Migrationen und Sync-Konfiguration dafür existieren. Die Guardian-Migration rollt diese fremde Funktion nicht mit aus. Vor Veröffentlichung des Schulaufgaben-Features dessen eigene Migrationen separat prüfen und abnehmen; den `school_assessments`-Stream erst aktivieren, wenn die Tabelle samt freigabegebundener RLS tatsächlich vorhanden ist. Die lokale Datei enthält diesen bestehenden Stream weiterhin als Feature-Konfiguration, nicht als Nachweis produktiver Verfügbarkeit.

Der Nutzer hat bestätigt, dass derzeit weder Zugang zu aktiven PowerSync-Regeln noch isolierte Eltern-/Kind-Testkonten vorhanden sind. Die lokale YAML ist daher kein Beleg für produktive Durchsetzung. Es gibt keine erreichbare Flutter-Debug-Sitzung für diesen Worktree; kein Simulator oder zweiter App-Prozess wurde gestartet.

## Deploy-Reihenfolge und Abnahme

1. Aktuelles produktives Schema einschließlich zusätzlicher Policies/RPCs erneut gegen den Stand prüfen. Auf einer isolierten Testdatenbank die Migration mit dem vollständigen aktuellen Schema und den bestehenden Triggern erproben. Der lokale PGlite-Test nutzt einen gezielten synthetischen Schemaausschnitt und ersetzt diesen Integrationsschritt nicht.
2. PowerSync-Zugang einrichten und aktive Regeln exportieren. In einem abgestimmten Wartungsfenster Migration, begrenzte Link-Projektion und Entfernung aller breiten Kinderprofil-Streams gemeinsam ausrollen. PowerSync umgeht RLS; ein nur teilweise ausgeführter Rollout erfüllt die Datenschutzanforderung nicht. Gegebenenfalls Sync während der Umstellung pausieren.
3. `notify-guardian-link` einschließlich `handler.ts` und `_shared/fcm_v1.ts` deployen. Vault konfigurieren und den Scheduler aus `supabase/ops` installieren. Cron-Ausführungen und Outbox-Versuche kontrollieren, ohne Tokens/Profilinhalte zu protokollieren.
4. Neue App-Version bereitstellen. Alte Versionen, die direkte Link-Updates oder breite Profilabfragen verwenden, sind nach der Härtung absichtlich nicht mehr vollständig kompatibel; den Update-Zwang bzw. das Wartungsfenster vor Freigabe festlegen. Kein pauschales `supabase db push` mit sämtlichen noch nicht produktiven Feature-Migrationen verwenden.
5. Mit zwei Eltern- und zwei Kinder-Testkonten direkte REST/RPC-Angriffe, alle vier Teilfreigaben/null Freigaben, Wechsel des aktiven Kindes, Entzug des letzten Kindes, parallele Antworten/Reminder, Offline-Neustart und Kontowechsel prüfen. Zusätzlich echte FCM-Zustellung bei Vordergrund, Hintergrund/Kaltstart, verweigerter Berechtigung, Tokenrotation und Teilversand abnehmen. Aktive Sync-Regeln und tatsächliche Datenauslieferung kontrollieren.

## Lokale Prüfungen

- SQL: `PGLITE_MODULE=/pfad/zu/@electric-sql/pglite/dist/index.js node supabase/tests/guardian_link_security.mjs` (getestet mit PGlite 0.3.14). Prüft echte SQL-Operationen/RLS unter `authenticated`, Rollen-/Teilnehmermanipulation, NULL-Parameter, minimale Suche, Zustimmung, Konflikte, Entzug, Wiederanfrage, Freigabeprojektionen, Push-Zielauswahl und Workerrechte.
- Function: `deno check supabase/functions/notify-guardian-link/index.ts`; `deno test --allow-env supabase/functions/notify-guardian-link/handler_test.ts`. Die Tests ersetzen den HTTP-Transport und FCM; sie senden keine echten Nachrichten.
- Flutter: Guardian-Tests unter `test/features/login` und `test/features/settings`, Suchergebnis- und Benachrichtigungs-Onboarding-Tests. Neue Tests prüfen den realen Router, echte Widgets, HTTP-Repository-Verhalten, veraltete Serverantworten, Dialogspeicherung und große Schrift.
- Visuelle Artefakte: `guardian_flow_widgets_test.dart` rendert echte Widgets mit synthetischen Namen, gebündeltem Libre Baskerville und Flutter-Roboto/Material Icons nach `/private/tmp/chrono-guardian-preview/`. Dies zeigt das getestete Flutter-Layout, nicht die native iOS-Push-Darstellung oder einen vollständigen Zwei-Geräte-Ablauf.

## Abschließender Prüfstand

- `flutter analyze lib test/features/login test/features/settings test/core/startup`: keine Befunde.
- Gesamter Lauf für `test/features/login`, `test/features/settings` und `test/core/startup`: 119 Tests bestanden. Abschließend alle vier HTTP-Repository-Tests bestanden, einschließlich dauerhaft gespeichertem Widerruf bei fehlgeschlagenem Folgeabruf und verständlichem Netzwerkfehler beim Erinnern. Die letzte Repository-Anpassung wurde erneut ohne Analysebefund geprüft. Dies ist kein Lauf der gesamten projektweiten Testsuite.
- SQL-Sicherheitstest mit PGlite 0.3.14: bestanden, einschließlich zweier Eltern-/Kindpaare, Rollen-/Spaltenrechten, Versionskonflikten, aktivem Kind und Outbox-Leases.
- Deno-Typprüfung bestanden; fünf Function-Tests bestanden. Keine echten FCM-Nachrichten verschickt.
- `git diff --check`: ohne Befund. Fremde Änderungen im Ausgangsworktree bleiben unangetastet.
- Kein produktives Deployment. Vollständiges Bestands-Schema in isolierter Umgebung, aktive PowerSync-Regeln, Scheduler/Vault und echter Zwei-Konten-/Geräteablauf bleiben vor Freigabe verbindlich zu prüfen.
