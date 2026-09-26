# E2E-Lauf v1 (Branch `test/e2e-v1`)

Stand 26.09.2026. Ende-zu-Ende-Test der App (Release-Stand 1.0.0 aus `origin/main`) headless gegen den Mock-NAS und
auf echten Geräten gegen das echte NAS. Findings stehen in `docs/E2E-FINDINGS.md`. Screenshots, uiautomator-Dumps und
Logcat liegen nur lokal unter `.e2e/` (in `.gitignore`), weil sie echte Dateinamen enthalten.

## Phase 0 – Rahmen (Antworten des Nutzers)

| Frage | Antwort |
| --- | --- |
| Zugangsdaten | Nicht in der Shell gesetzt; `~/.synology-explorer.env` (NAS_URL, NAS_USER, NAS_PASS, kein NAS_OTP) darf je Befehl per `source` geladen werden |
| Geräte | OnePlus 9 Pro `4c5ce6f6` (API 36) und Samsung A40 `R58MC1T7R4D` (API 30), wie in CLAUDE.md. „Aktiv lassen“ ist auf beiden bereits eingeschaltet (daher kein `svc power stayon` nötig, am Ende nichts zurückzusetzen). OnePlus hat eine PIN-Sperre; der Nutzer hat die PIN für das Entsperren per adb freigegeben (steht in keiner Datei) |
| audioserver-Schleife OnePlus | Unbekannt, ob behoben – wird beim Audio-Test beobachtet |
| `svc wifi disable/enable` | erlaubt |
| Testdaten | Nicht vorgegeben; per `SYNO.FileStation.Search` (lesend) selbst suchen |
| Test-Favorit `_e2e_<ts>` | erlaubt (anlegen und wieder löschen) |
| Testordner mit Schreibrecht | gibt es nicht; `CreateFolder` im Share einmal versuchen (erwartet 407), sonst nur Fehlerpfade |
| Freigabelink | erlaubt (erwartet 407; bei Erfolg sofort löschen) |
| `pm clear` | auf beiden Geräten erlaubt |
| Überspringen | nichts (außer den Sperren aus dem Auftrag: Auto-Upload nie einschalten, Papierkorb nur listen) |
| Release-Build | Keystore liegt als GitHub-Secret; lokal wird versucht, ohne `key.properties` zu bauen |

## Phase 1 – Capabilities des Testkontos (curl, 26.09.2026)

Ein einziger sichtbarer Share (`share_right: RW`, laut ACL aber ohne Schreib-/Anfügerecht, Löschen erlaubt). Testdaten per `Search` gefunden: Audio-Ordner mit 8 MP3 + 3 JPG, Ordner mit
PDF/TXT/MP3, MP4 (42 MB), DOCX (89 KB), großer Ordner für DirSize (≈ 8 000 Dateien, ≈ 100 GB). **Nicht vorhanden:**
FLAC, Markdown (nur `.txt`), HEIC.

| Aufruf | Ergebnis | Folge für „bestanden“ |
| --- | --- | --- |
| `SYNO.API.Info` / Login (`enable_device_token`) | ok, `device_id` wie SPIKE.md | Login muss klappen |
| `list_share additional=perm` | ok (s. o.) | 05 zeigt einen Share |
| `list` / `getinfo` (owner, perm, real_path, time, type) | ok | 06, 10 vollständig |
| `Thumb size=small` / `medium` / `xl` (JPG) | 200 JPEG / 200 JPEG / 404 HTML | 07 zeigt echte Thumbs |
| `Download mode=open` + Range, **GET** | 206 mit `Content-Range` | Seek muss gehen |
| `Download mode=open` + Range, **POST** | **200, ganze Datei** (Range ignoriert) | App nutzt GET – ok |
| `Favorite list status_filter=all additional=[real_path,perm]` | ok, 5 bestehende Ordner-Favoriten | Phase 6 möglich |
| `Favorite add` / erneut / `delete` / erneut | success / **800** / success / success | 800 = „schon vorhanden“ |
| `Favorite add` auf Datei oder nicht existierenden Pfad | success, aber `status: broken`, `isdir: false` | nur Ordner sinnvoll (s. Annahmen) |
| `Sharing list` / `create` / `delete` (unbekannte ID) | leer / **407** / 401 | 22: saubere Fehlermeldung, 23: Leerzustand |
| `Search start/list/stop/clean` (Muster, `extension`) | ok, `taskid` JSON-kodiert | 11 liefert Treffer |
| `DirSize start/status/stop` | ok; `status` nach `stop`/`finished` → 599 | 10 berechnet, Abbruch ok |
| `List #recycle` | **407** | 24: Share nicht angeboten |
| `CreateFolder <Share>/_e2e_<ts>` | **1100 / 407** – kein Testordner | alle Schreibaktionen: nur Fehlerpfad |
| `Upload` in nicht existierenden Ordner | 408 (ohne `create_parents`), 407 (mit) | 14/20: Fehlermeldung, kein Endlos-Retry |
| `Rename` auf nicht existierende Datei im Testordner-Pfad | 1200 / 408 | Fehlermeldung |
| `CopyMove` / `Delete` auf nicht existierende Datei | `start` ok, `status` 599 bzw. `finished` ohne Fehler | Delete kann auf echten Dateien klappen (`del: true`) → nie auf echten Dateien |

Auf dem NAS blieb nach Phase 1 nichts zurück: Der Share enthält weiter nur den bisherigen Ordner, die Favoritenliste
ist vor und nach dem Test identisch (drei temporäre `_e2e_…`-Favoriten angelegt und gelöscht), keine Freigabelinks.

## Phase 2 – Statisches Audit

Vier Agents (Navigation, Screens gegen Mockups, Fehlerpfade/Lebenszyklus, Hygiene/Sicherheit) lasen den Code; 56
Findings, dedupliziert in `docs/E2E-FINDINGS.md` (E2E-001 bis E2E-056). Ausgangslage: `flutter analyze` und
`dart format` sauber, 278 Tests grün, keine TODO/FIXME, kein Logging von Passwörtern/SIDs, TLS-Regeln eingehalten.

## Phase 3 – Headless E2E gegen den Mock-NAS

`test/e2e/` startet die komplette App (`NuvoExplorerApp` in einem `ProviderScope`) mit echtem HTTP gegen
`tool/mock_nas` auf einem freien Loopback-Port. Gefaked sind nur Plattform-Teile: drift in-memory, Secure Storage,
path_provider, AudioController (Zustände), Benachrichtigungen, WorkManager, Fotozugriff, file_picker. Jeder Flow endet
mit Zurück per Zurück-Pfeil **und** per `handlePopRoute()` (Android-Zurück); danach baut `E2E.dispose()` die App ab,
und flutter_test prüft, dass keine Timer offen sind und keine Exception im `FlutterError`-Handler lag.

| Flow | Datei | Ergebnis |
| --- | --- | --- |
| 1 Erststart, Validierung, 400/403/404, 2FA, Start | `flow_01_login_test.dart` | grün |
| 2 Share, Ordner, Sortierung, Paging (520 Einträge), Grid | `flow_02_browse_test.dart` | grün; E2E-064 |
| 3 Kebab, Info, DirSize-Stop beim Schließen, Favorit | `flow_03_info_favorite_test.dart` | grün |
| 4 Suche mit `finished` ohne `total`, Filter, Stop/Clean beim Verlassen | `flow_04_search_test.dart` | grün |
| 5 Ordner abspielen, Mini-Player, 12, 13, Shuffle/Repeat | `flow_05_audio_test.dart` | grün |
| 6 Viewer 15, 17–19 öffnen/zurück, Download verweigert | `flow_06_viewers_test.dart` | grün; Video (16) geskippt (media_kit headless ohne libmpv) |
| 7 Auswahlmodus, alle Aktionen, Upload-Sheet, Verweigerung | `flow_07_selection_test.dart` | grün bis auf E2E-057 (geskippt) |
| 8 Transfers, Offline, Freigabelinks, Papierkorb, Auto-Upload-Formular, Einstellungen | `flow_08_transfers_settings_test.dart` | grün; E2E-059, E2E-062 |
| 9 Session abgelaufen: Re-Login, zweiter Fehler | `flow_09_session_test.dart` | grün; E2E-012/013/063 als auskommentierte Erwartung markiert |

Der Mock-NAS kann jetzt: Search als Task (optional erst `finished` ohne `total`), Paging in `/photo`, `getinfo` je
Pfad, `#recycle`-Listing, Schalter für Fehlerfälle (`MockNasControl`: SIDs ungültig machen, Login ablehnen,
Schreibaktionen mit 407 verweigern, Download-Fehler/502-HTML je Pfad).

## Phase 4 – Gerät gegen das echte NAS

**Werkzeug:** `tool/e2e/device.sh` über `adb.exe`. Semantik im Debug-Build (`--dart-define=E2E=true`) funktioniert:
`uiautomator dump` sieht Texte, Tooltips und Labels der Flutter-Widgets. Grenzen: Solange die App ständig Frames
erzeugt (laufende Wiedergabe, Video), scheitert der Dump („could not get idle state“) – dort wurde per Screenshot und
Koordinaten getippt. Textfelder sind ohne Label nicht auffindbar (E2E-060). Eingaben gehen zeichenweise, sonst
verliert die Tastatur Zeichen. Auf dem Samsung verdeckt die Tastatur die unteren Felder; dort wurde per Tab-Taste
zwischen Feldern gewechselt. Screenshots/Dumps/Logcat liegen nur lokal unter `.e2e/`.

Testdaten (per Search gefunden, hier anonymisiert): Ordner mit 8 MP3 und 3 JPG, Ordner mit 3 PDF/1 TXT/4 MP3,
DOCX (87 KB) im Unterordner einer Schulung, MP4 (40 MB, 480p), großer Ordner (≈ 8 000 Dateien).

### OnePlus 9 Pro (`4c5ce6f6`, Android 16) – voller Ablauf

| Schritt | Ergebnis |
| --- | --- |
| 1 `pm clear`, Server anlegen, verbinden | bestanden. Bitwarden bot an, das Passwort zu speichern – abgelehnt |
| 2 Start (05) | Share „Nur Lesen“, keine Favoriten (lokal leer, NAS-Favoriten erst nach Phase 6), Zuletzt nach Nutzung gefüllt |
| 3 Liste/Grid, Sortierung, Pull-to-Refresh, Zurück je Ebene | bestanden; Breadcrumb-Sprung zerstört den Stack (E2E-017 bestätigt) |
| 4 Thumbnails | echte Vorschaubilder (`size=small`, 2–4 KB je Bild), kein Dauer-Spinner, kein Massen-Download |
| 5 Audio | Ordner abspielen, Mini-Player, Now Playing, Seek (Range), nächster Titel, Queue, Shuffle/Repeat, Hintergrund mit Foreground-Service (`mediaPlayback`) bestanden. **audioserver-Schleife des Geräts besteht weiter** (Neustarts im Log, Wiedergabe stockt, ~50 % Echtzeit) – kein App-Fehler, Dauertest deshalb auf dem A40 |
| 6 Viewer | Bild (Galerie per schnellem Wisch, Thumbnail-Streifen, Info), PDF (Suche 30 Treffer), Text, DOCX, Video (Querformat, Controls, Rückkehr ins Hochformat) bestanden. PDF-Suche + Zurück schließt den Viewer (E2E-016), Löschen/Herunterladen „ab M4“ deaktiviert (E2E-003/004) |
| 7 Suche | Treffer, Filter „Dokumente“, Verlassen während des Pollings bestanden; Datei-Treffer öffnet nur den Ordner (E2E-020) |
| 8 Info, DirSize | großer Ordner: gleiche Werte wie curl; Verlassen während der Berechnung ohne Fehler |
| 9 Schreibaktionen | Upload/Neuer Ordner: App meldet vorab „Keine Schreibrechte“ (bestanden). Umbenennen/Verschieben deaktiviert. Löschen: Dialog mit Papierkorb-Hinweis, **abgebrochen** (nie echte Dateien). Freigabelink: „Keine Berechtigung.“ (bestanden). **Kopieren → 407 → schwarzer Bildschirm (E2E-057, crash)**; am NAS nichts kopiert (curl geprüft). Upload aus dem Dateipicker war per UI nicht auslösbar (Sperre vorab), `_e2e.txt` wurde deshalb nicht aufs Handy gelegt |
| 10 Freigabelinks, Papierkorb, Transfers, Offline | Links: Leerzustand. Papierkorb: „nur für Admins sichtbar“ (bestanden). Offline: TXT geladen, ohne WLAN lokal geöffnet (Mobilfunk blieb an, siehe A40). Benachrichtigungs-Berechtigung beim ersten Transfer erlaubt. Snackbar „Download eingereiht“ blieb minutenlang stehen und verdeckte die Design-Zeile (E2E-015) |
| 11 Einstellungen | Wiedergabe, Cache-Limit (500 MB → 1 GB), Design Hell/Dunkel, Sprache de/en/System, Über & Lizenzen, Abmelden, erneut Anmelden bestanden. Hell: Viewer-Overlay unlesbar (E2E-047). „Server verwalten“ ohne Zurück (E2E-009) |
| 12 Robustheit | Rotation Querformat ohne Overflow; App-Kill während der Wiedergabe → „Bei 0:11 fortsetzen?“ bestanden; Session-Ablauf nur headless (Flow 9) |

Logcat im ganzen Lauf: genau eine Exception (E2E-057), kein ANR.

### Samsung A40 (`R58MC1T7R4D`, Android 11) – gekürzt (1–3, 5, 6, 11)

| Schritt | Ergebnis |
| --- | --- |
| 1 Anmelden | bestanden, kein Zertifikat-Dialog (ISRG-Root-Fix wirkt). Die Tastatur verdeckt „Verbinden“ (E2E-058); Absenden per Enter |
| 2–3 Navigation, Grid, Zurück-Kette | bestanden; 360 dp kürzt „Abspielen“ (E2E-065) |
| 5 Audio | 2 min im Hintergrund flüssig (Position 125 s nach ~130 s), Foreground-Service aktiv. Video öffnen pausiert die Musik nicht (E2E-045). Video-Ton stoppt im Hintergrund (E2E-044 nicht reproduzierbar) |
| 6 Viewer | PDF, Text, DOCX, Bild-Galerie bestanden |
| 11 Einstellungen | Sprache, Abmelden, erneut Anmelden bestanden; Cache-Wert gekürzt (E2E-065) |
| extra: ohne Netz starten (keine SIM) | ~17 s Spinner, dann Server-Liste ohne Weg zu Offline/Einstellungen (E2E-001, E2E-037) |

**Geräte-Unterschiede:** Das A40 zeigt beim ersten Video den Samsung-Vollbild-Hinweis (Systemdialog). Nach dem Video
bleibt es bei aktiver Auto-Rotation im Querformat, solange das Gerät flach liegt (Plattformverhalten). Die
Samsung-Tastatur hat eine Symbolleiste, die Tipps auf verdeckte Felder abfängt.

## Phase 5 – Fix-Schleife

65 Findings, sortiert nach Schweregrad, behoben in je einem Commit mit Regressionstest (Details, Ursache und Test je
Finding in `docs/E2E-FINDINGS.md`). Unabhängige Bereiche liefen parallel in eigenen Worktrees (Viewer; Browser;
Einstellungen/Freigaben/Transfers/Audio), Kern/Server/Session/Router im Hauptzweig; danach zusammengeführt, alle Tests
grün. Nachprüfung am Gerät nach den Fix-Serien:

| Gerät | nachgeprüft (bestanden) |
| --- | --- |
| OnePlus | E2E-009/010 (01 mit Zurück), 022 (Hinweis sichtbar), 060 (Felder mit Label im Dump), 057 („Keine Berechtigung.“ statt schwarzem Bildschirm), 018 (Picker: Zurück eine Ebene hoch), 016 (PDF: erst Suche, dann Viewer), 015 (Snackbar verschwindet), 020 (Suchtreffer öffnet DOCX), 059 (Zurück auf Transfers → Dateien-Tab mit offenem Ordner), 047 (Bild-Viewer im hellen Design lesbar), 003 (Löschen-Dialog, abgebrochen) |
| A40 | 065 („Abspielen“ auf 360 dp vollständig), 045 (Video pausiert Musik: AudioTrack `paused`, Video `started`) |

In keinem Nachprüf-Lauf gab es `E/flutter`-Einträge im Logcat.

## Phase 6 – Favoriten vom NAS

Umgesetzt wie in CONCEPT.md Abschnitt 2/4 (neu): Ordner-Favoriten kommen aus `SYNO.FileStation.Favorite`, drift ist
Cache (Schema v7). Headless: `test/features/browser/favorites_sync_test.dart` (Zustandsregel, 800, 105),
`test/e2e/flow_10_nas_favorites_test.dart` (05: Anzeige, broken gedämpft mit Tooltip, Pull-to-Refresh, Verweigerung,
lokaler Datei-Favorit öffnet den Viewer), `test/core/storage/migration_test.dart`.

Am Gerät (OnePlus): 05 zeigt die fünf bestehenden NAS-Favoriten des Kontos. Test-Favorit `_e2e_<ts>` per curl
angelegt → erscheint nach Pull-to-Refresh als Chip, Chip öffnet den Ordner → über Sheet 09 „Aus Favoriten entfernen“
gelöscht → per curl bestätigt: Favoritenliste identisch mit dem Stand aus Phase 1. In DS File selbst nicht prüfbar
(keine DS-File-Installation im Zugriff). Anlegen **über die App** wurde am echten NAS bewusst nicht ausgeführt: Die App
benennt den Favoriten nach dem Ordner, der Auftrag erlaubt nur einen Test-Favoriten `_e2e_<ts>`; die Parameterform
(`path`/`name` roh) ist per curl (Phase 1) und im Mock abgedeckt.

## Phase 7 – Abschluss

- Review des gesamten Diffs durch einen frischen Agent, der die Fixes nicht kannte: kein Blocker; Sicherheitsregeln
  (höchstens ein Login je Request-Kette, kein Login nach gescheitertem stillem Login, keine SIDs im Log, TLS
  unverändert), keine Secrets/echten Namen im Repo, Tests je Fix in der Stichprobe vorhanden. 14 kleinere Punkte,
  alle bearbeitet:

  | Review | Ergebnis |
  | --- | --- |
  | R-01 Lücke beim 105-Re-Login | behoben 67a5b4e |
  | R-02 Favoriten-105 löste stillen Login aus | behoben 67a5b4e (Test in favorites_sync_test) |
  | R-03 Update ersetzt lokale Ordner-Favoriten | dokumentiert (CONCEPT 2), vom Auftrag so erlaubt |
  | R-04 Sitzungsverlust unter gepushtem 01 | behoben abb224e (regression_servers_test) |
  | R-05 fehlender Test für Abmelden unter gepushtem 01 | ergänzt abb224e |
  | R-06 jeder 502 als „Nicht gefunden“ | behoben b79b431 (getinfo prüft, download_502_test) |
  | R-07 kaputte Favoriten nicht entfernbar | behoben d7e65ce (flow_10) |
  | R-08 Doku zu Datei-Favoriten widersprüchlich | Doku korrigiert |
  | R-09 jeder unbekannte Code als „nicht verfügbar“ | behoben d7e65ce |
  | R-10 Ablauf-Meldung erschien mehrfach | behoben abb224e |
  | R-11 Passwort nur zum Prüfen gelesen | behoben 67a5b4e (containsKey) |
  | R-12 Race beim Vorbelegen von „Passwort merken“ | behoben 0a67425 |
  | R-13 Begründung „list vor delete“ falsch | Kommentar und CONCEPT 4 korrigiert |
  | R-14 zu viele Kontodetails in E2E-RUN | anonymisiert (Share-Name, ACL-Details) |

- NAS-Endzustand per curl: keine Freigabelinks, Share-Wurzel unverändert (kein Testordner – `CreateFolder` wurde
  verweigert), Favoritenliste identisch mit Phase 1, curl-Session abgemeldet.
- Handys: `_e2e.txt` wurde nie angelegt (Upload per UI gesperrt), „Aktiv lassen“ war schon an und wurde nicht
  verändert, Rotation (OnePlus) und WLAN (beide) sind zurückgesetzt, Design der App wieder „Dunkel“. Die App bleibt auf
  beiden Geräten installiert und angemeldet (OnePlus: eine Offline-Kopie der Test-TXT in den App-Daten).
- `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug` und `--release` grün. Der Release-Build
  nutzt ohne `key.properties` die Debug-Signatur (Fallback im Build-Skript); der erste Release-Lauf brach einmal ohne
  klare Meldung ab, die Wiederholung lief durch.

## Nicht testbar und warum

| Punkt | Grund |
| --- | --- |
| Upload, Neuer Ordner, Umbenennen, Verschieben, Löschen mit Erfolg am echten NAS | Konto ohne Schreibrecht (407); nur Fehlerpfade am Gerät, Erfolgspfade headless gegen den Mock |
| Freigabelink erstellen/löschen mit Erfolg | Konto ohne Freigaberecht (407) |
| Papierkorb listen/wiederherstellen | `#recycle` nur für Admins (407); headless mit Mock |
| 2FA/OTP am echten NAS | 2FA auf dem Konto aus |
| Zertifikat-Dialog (03) am echten NAS | gültiges Zertifikat, kein Pinning nötig |
| Markdown-Viewer am echten NAS | keine `.md`-Datei auf dem NAS; headless geprüft |
| Pinch-Zoom | per `adb input` nicht ausführbar |
| Kopfhörer-Tasten, Sperrbildschirm-Steuerung | in diesem Lauf nicht geprüft (in SPIKE.md 3b auf dem A40 bestanden) |
| Audio-Dauerlauf auf dem OnePlus | audioserver-Schleife des Geräts (unabhängig von der App) |
| Session-Ablauf am Gerät | SID lässt sich nicht von außen ungültig machen; nur headless (Flow 9) |
| Echter Offline-Zustand auf dem OnePlus | SIM/Mobilfunk bleibt bei `svc wifi disable` aktiv; auf dem A40 (ohne SIM) geprüft |
| iOS | kein Mac/iPhone in diesem Lauf |

## Rückstände

- **Am NAS:** keine Dateien, Ordner, Links oder Favoriten. Die curl-Anmeldungen mit `enable_device_token=yes`
  (Gerätename `e2e-curl`) und die App-Anmeldungen der beiden Handys können unter DSM › Persönlich › Sicherheit ›
  „Vertrauenswürdige Geräte“ als Einträge stehen – bei Bedarf dort entfernen (für das Konto per API nicht löschbar).
- **Am Handy:** siehe Phase 7; zusätzlich auf dem A40 bitte die Samsung-Tastatur-Einstellungen kurz ansehen (siehe
  Annahmen).

## Annahmen

- NAS-Favoriten nur für Ordner: DSM nimmt Dateien als Favorit an, meldet sie aber sofort als `broken`. Ordner-Favoriten
  gehen deshalb aufs NAS, Datei-Favoriten bleiben lokal (siehe unten und CONCEPT.md Abschnitt 2).
- Schweregrad „sicherheit“ ergänzt die vorgegebene Skala (crash > blockiert > sicherheit > navigation > fehlermeldung
  > kosmetik), weil Backup-/Log-Lecks weder „blockiert“ noch „kosmetik“ sind.
- Auf dem A40 öffnete ein Tipp auf die Tastatur-Symbolleiste versehentlich die Einstellungen der Samsung-Tastatur. Es
  wurde dort nichts bewusst umgeschaltet, die sichtbaren Schalter standen unverändert auf „Ein“. **Bitte kurz prüfen.**
- Datei-Favoriten bleiben lokal, Ordner-Favoriten kommen vom NAS (Mischform statt „alles vom NAS“): DSM führt Dateien
  als Favorit nur als `broken`, DS File würde sie als kaputte Einträge zeigen; die Mockups 12 und 15 zeigen aber einen
  Favoriten-Stern für Dateien. Lokale Ordner-Favoriten werden beim ersten Abgleich durch die NAS-Liste ersetzt.
- Zurück auf dem Root von Offline/Transfers/Einstellungen führt zum Dateien-Tab (Material-Konvention), erst dort
  verlässt Zurück die App (E2E-059).
- Nach gescheitertem stillem Re-Login verwirft die App die Session und zeigt 01 mit Meldung (CONCEPT 4); danach landet
  man nach dem Login auf 05, nicht am alten Ort (E2E-012/013).
- Markdown-Viewer ist am echten NAS nicht testbar (keine `.md`-Datei); geprüft werden `.txt` und headless Markdown.
