# Chrono – dauerhafte Arbeitsregeln für Codex

## Hot Reload im iOS-Simulator

- Wenn du Dart-Code der App geändert hast und Chrono in einem iOS-Simulator über eine laufende Flutter-Debug-Sitzung geöffnet ist, führe nach der zusammenhängenden Änderung einen Hot Reload in dieser Sitzung aus.
- Verwende dafür die bereits laufende Flutter-Sitzung. Starte keinen zweiten Simulator oder `flutter run`-Prozess und beende die bestehende Sitzung nicht.
- Prüfe, ob der Hot Reload erfolgreich war. Wenn keine erreichbare Flutter-Debug-Sitzung besteht, der Simulator nicht verfügbar ist oder ein vollständiger Neustart nötig wäre, melde das knapp und starte nichts eigenmächtig neu.
- Änderungen an nativen iOS-/Android-Dateien, Abhängigkeiten oder App-Konfiguration können einen vollständigen Neustart erfordern. Weise darauf hin, statt sie als Hot-Reload-fähig darzustellen.

## Commits und GitHub

- Erstelle regelmäßig einen Commit, sobald eine zusammenhängende, sinnvolle Änderung abgeschlossen und – sofern für die Aufgabe verlangt – überprüft ist. Warte nicht bis zum Ende eines großen Vorhabens, aber erstelle auch keine Commits für einzelne Kleinstschritte.
- Verwende eine kurze, aussagekräftige Commit-Message im Conventional-Commits-Stil, zum Beispiel `feat(calendar): add event filters` oder `fix(login): handle expired sessions`.
- Committe ausschließlich Änderungen, die du in der aktuellen Aufgabe selbst vorgenommen hast. Übernimm keine bereits vorhandenen oder fremden Änderungen aus dem Arbeitsverzeichnis; verwende insbesondere nicht pauschal `git add -A`.
- Push den Commit zum konfigurierten GitHub-Upstream, wenn der aktuelle Branch und sein Upstream eindeutig sind und der Push ohne Force-Push möglich ist.
- Führe niemals einen Force-Push aus und ändere oder überschreibe keine vorhandenen Commits. Wenn der Branch detached ist, kein klarer Upstream besteht oder der Push nicht sicher zugeordnet werden kann, erstelle keinen Push und melde kurz, was dafür fehlt.
