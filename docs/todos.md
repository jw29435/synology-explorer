# Manuelle Aufgaben nach dem E2E-Lauf v1

Stand 26.09.2026, Branch `test/e2e-v1`. Details zu jedem Punkt: `docs/E2E-RUN.md` und `docs/E2E-FINDINGS.md`.

## 1. Branch pushen und PR anlegen

Der Push wurde in der Session blockiert, der Branch liegt nur lokal.

```sh
git push -u origin test/e2e-v1
gh pr create --base main --head test/e2e-v1 \
  --title "test: E2E-Lauf v1 – Findings behoben, Favoriten vom NAS" \
  --body-file <PR-Text>
```

Der PR-Text lag im Scratchpad der Session. Falls er weg ist: Zusammenfassung aus `docs/E2E-RUN.md`
(Phasen 5–7, „Nicht testbar“, „Rückstände“) übernehmen. Danach prüfen, ob die CI grün ist.

## 2. Aufräumen

- [ ] **DSM › Persönlich › Sicherheit › „Vertrauenswürdige Geräte“:** Den Eintrag `e2e-curl` von den curl-Tests
      entfernen. Einträge der beiden Handys nur entfernen, wenn gewünscht (die App meldet sich sonst beim nächsten
      Mal ohne Geräte-Token an).
- [ ] **Samsung A40:** Die Einstellungen der Samsung-Tastatur kurz ansehen. Ein Tipp hat sie versehentlich geöffnet;
      sichtbar wurde nichts verändert (Texterkennung, Emojis, Sticker, Symbolleiste standen auf „Ein“).
- [ ] Optional: Die App auf beiden Handys zurücksetzen (`pm clear`). Sie ist mit dem Testkonto angemeldet, auf dem
      OnePlus liegt eine Offline-Kopie einer Test-TXT.

## 3. Mit einem Konto mit Schreib- und Freigaberecht testen

Das Testkonto darf nicht schreiben (407). Am echten NAS sind deshalb nur die Fehlerpfade geprüft, die Erfolgspfade
nur gegen den Mock. Bitte in einem Testordner prüfen:

- [ ] Upload über das „+“-Menü (Dateien, Fotos/Videos, Kamera), mit und ohne „Überschreiben“. Erscheint die Datei
      nach dem Upload ohne Pull-to-Refresh in der Liste (E2E-036)?
- [ ] Neuer Ordner, Umbenennen, Verschieben, Kopieren (Sheet 09 und Auswahlmodus 08) mit Fortschrittsdialog.
      Zurück während des Dialogs darf nichts abbrechen (E2E-030).
- [ ] Löschen, auch aus dem Bild-Viewer (E2E-003: danach nächstes Bild, beim letzten schließt der Viewer).
- [ ] Papierkorb (24) mit einem Admin-Konto: Listen, Wiederherstellen, Endgültig löschen. Bei mehr als 500 Einträgen
      das Nachladen (E2E-040).
- [ ] Freigabelinks: Link erstellen (Ablauf, Passwort), kopieren/teilen, in 23 löschen und „Aufräumen“, jeweils mit
      Bestätigungsdialog (E2E-035). Dabei die offenen Punkte aus SPIKE.md klären: URL-Host des Links, Format von
      `date_expired`.
- [ ] DOCX-Viewer „Herunterladen“: Landet die Datei in Transfers und Offline (E2E-004)?

## 4. Favoriten (Phase 6)

- [ ] In der App über Sheet 09 einen Ordner zu den Favoriten hinzufügen. Erscheint er in DS File auf einem anderen
      Gerät? Das wurde am echten NAS bewusst nicht gemacht, weil die App den Favoriten nach dem Ordner benennt (nicht
      `_e2e_…`).
- [ ] Umgekehrt: In DS File einen Favoriten anlegen, in der App auf Screen 05 nach unten ziehen – erscheint er?
- [ ] Einen Favoriten, dessen Ordner es nicht mehr gibt, als gedämpften Chip mit „x“ entfernen.
- [ ] Nach dem Update von v1.0 ersetzt der erste Abgleich die bisher lokal markierten Ordner-Favoriten durch die
      NAS-Liste. Falls es schon Nutzer gibt, dies im Changelog erwähnen.

## 5. Gerätetests, die offen sind

- [ ] **OnePlus: Audio-Problem des Handys beheben**, dann die Audio-Tests nachholen. Der `audioserver` startet alle
      paar Sekunden neu (vermutlich „Hey Google“/SoundTrigger), unabhängig von der App. Das Handy neu starten oder
      „Hey Google“ abschalten. Danach auf dem OnePlus prüfen: 15 min Wiedergabe im Hintergrund, Steuerung vom
      Sperrbildschirm, Kopfhörertaste, Wechsel WLAN → Mobilfunk mitten im Titel.
- [ ] **Offline-Wiedergabe beim Anmelden (E2E-046):** Auf dem A40 eine Offline-MP3 abspielen, dann anmelden – die
      Musik muss weiterlaufen.
- [ ] **Mini-Player bei Fehlern (E2E-031):** Titelwechsel ohne Netz – zeigt der Mini-Player Fehler-Icon und Text?
- [ ] **Video (E2E-027/028/041/052):**
  - WLAN während der Wiedergabe aus: Kommt nach dem Spinner ein Hinweis mit „Erneut versuchen“, und geht es danach an
    der alten Stelle weiter?
  - Nicht unterstützter Codec: Erscheint „kann nicht abgespielt werden“?
  - Resume-Karte im Hochformat auf dem A40 ansehen.
- [ ] **Breadcrumb auf 360 dp mit großer Systemschrift (E2E-053):** Läuft die 72-px-Toolbar über?
- [ ] **Ordner-Picker (E2E-018):** Ein Tipp neben das Sheet geht jetzt eine Ebene hoch statt zu schließen – so
      gewollt?
- [ ] **Design „Hell“:** Das Grid mit Video und HEIC ansehen (E2E-048).

## 6. Nicht testbar gewesen

- [ ] **2FA:** Auf einem Konto mit aktiver 2FA anmelden, „Dieses Gerät merken“; der nächste Login muss ohne Code
      gehen. Danach falscher Code → Fehlermeldung, kein automatischer Neuversuch.
- [ ] **Zertifikat-Dialog (03):** Über eine Adresse mit selbstsigniertem Zertifikat (z. B. LAN-IP:5001) verbinden,
      Fingerprint bestätigen. Danach ein geändertes Zertifikat → Verbindung muss blockiert werden.
- [ ] **iOS:** Build und Grundfunktionen. Außerdem **E2E-008 als Issue anlegen:** Offline-Dateien unter iOS mit
      `NSURLIsExcludedFromBackupKey` vom iCloud-Backup ausnehmen (braucht nativen Code).
- [ ] **Session-Ablauf am Gerät:** Die App über Nacht angemeldet lassen, dann etwas öffnen. Mit gemerktem Passwort
      muss es ohne Rückfrage weitergehen; ohne gemerktes Passwort kommt die Server-Liste mit der Meldung „Sitzung
      abgelaufen“.
- [ ] **Markdown-Viewer** mit einer echten `.md`-Datei (auf dem NAS gab es keine).

## 7. Release

- [ ] Den Release-Build einmal mit dem echten Keystore (GitHub-Secret) bauen lassen. Lokal wurde er ohne
      `key.properties` mit der Debug-Signatur gebaut; der erste lokale Release-Lauf brach einmal ohne klare Meldung
      ab, der zweite lief durch.
- [x] Nach dem Merge den offenen release-please-PR (#9, „release 1.0.0“) prüfen – die Fixes gehören in den Changelog.
      Erledigt: geschlossen, 0.1.1 manuell als Pre-Release.
