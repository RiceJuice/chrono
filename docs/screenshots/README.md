# App-Screenshots für die GitHub-README

Lege hier **vier App-Store-Screenshots** ab, die in der [README.md](../../README.md) angezeigt werden.

## Dateinamen (exakt so benennen)

| Datei | Empfohlener Inhalt |
|---|---|
| `01-tagesansicht.png` | Tagesansicht mit Stundenplan, Chor oder Events |
| `02-wochenansicht.png` | Wochenraster mit farbigen Terminkarten |
| `03-filter-suche.png` | Kalenderfilter, Suche oder Termindetails |
| `04-hausaufgaben.png` | Hausaufgaben, Einstellungen oder Elternmodus |

## Format & Größe

- **Format:** PNG oder JPG (PNG bevorzugt, schärfer bei UI-Screenshots)
- **Seitenverhältnis:** 9:19,5 (iPhone) oder die Größe, die du im App Store nutzt — z. B. **1290 × 2796 px**
- **Dateigröße:** unter ~1 MB pro Bild (GitHub rendert große Dateien langsamer)

## Screenshots einfügen

1. Screenshots vom iPhone/Mac exportieren oder in Xcode/App Store Connect herunterladen.
2. Die vier Dateien in **diesen Ordner** (`docs/screenshots/`) legen — mit den Namen aus der Tabelle oben.
3. In Git committen und pushen:

   ```bash
   git add docs/screenshots/
   git commit -m "Screenshots für README hinzugefügt"
   git push
   ```

4. Die README verweist bereits auf diese Pfade — nach dem Push erscheinen die Bilder automatisch auf GitHub.

## Alternative Pfade

Wenn du andere Dateinamen nutzen willst, passe die vier `![…](docs/screenshots/…)`-Zeilen in der [README.md](../../README.md) an.

## Tipp: Platzhalter testen

Solange noch keine echten Screenshots da sind, zeigt GitHub ein kaputtes Bild-Icon. Das ist normal — sobald die Dateien committed sind, werden sie ersetzt.
