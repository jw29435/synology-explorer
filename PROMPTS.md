# Claude-Code-Prompts – Synology Explorer

Reihenfolge einhalten; jeder Prompt ist eine eigene Claude-Code-Session (lokal im Repo unter WSL2) und endet mit einem PR.
Vor Prompt 0 müssen im Repo liegen: `CLAUDE.md`, `docs/CONCEPT.md`, `docs/mockups/01…26.png`.
Session starten: `cd ~/dev/synology-explorer && claude`, dann den Prompt einfügen. Für eine neue Session `/clear` oder `claude` neu starten.
Prompt 1b und 3b laufen in derselben Session wie 1 bzw. 3 direkt im Anschluss – das NAS und das Handy sind lokal erreichbar.

Wiederkehrende Kopfzeile – **an den Anfang jedes Prompts stellen**:

```
Lies zuerst CLAUDE.md und docs/CONCEPT.md. Arbeite auf einem neuen Branch feat/<name>, erstelle am Ende einen PR
gegen main. Führe vor dem PR `dart format .`, `flutter analyze` und `flutter test` aus und behebe alles.
Fasse am Ende zusammen: was fertig ist, welche Annahmen du getroffen hast und was auf echtem NAS/Gerät geprüft werden muss.
```

---

## Prompt 0 – Bootstrap · Branch `feat/m0-bootstrap`

```
Setze das Flutter-Projekt "Synology Explorer" in diesem Repo auf. Ziel dieses Prompts ist ein lauffähiges, leeres
Gerüst mit CI, noch ohne Features.

1. `flutter create` mit Organisation `de.jw29435`, App-Name `synology_explorer`, nur Plattformen android und ios.
   Min. Android API 26, iOS Deployment Target 15. Kotlin DSL für Gradle beibehalten.
2. pubspec: alle Pakete aus CONCEPT.md Abschnitt 5 aufnehmen (Riverpod + Generator, go_router, dio, freezed,
   json_serializable, drift, flutter_secure_storage, just_audio, audio_service, media_kit, photo_view, pdfrx,
   flutter_markdown, flutter_localizations, plus build_runner und die Test-Pakete). Versionen: jeweils aktuelle
   stabile von pub.dev, mit Caret-Constraints.
3. Ordnerstruktur exakt wie CONCEPT.md Abschnitt 5 anlegen (app/, core/, features/…), jeweils mit einer kurzen
   README.md pro Feature-Ordner, die den Zweck beschreibt. Leere Feature-Ordner sind ok.
4. `lib/app/theme.dart` mit den Design-Tokens aus CLAUDE.md (dunkles Theme als Default, helles Theme vorbereitet),
   Manrope und JetBrains Mono über google_fonts einbinden.
5. `lib/app/router.dart` mit go_router: Shell-Route mit vier Tabs (Dateien, Offline, Transfers, Einstellungen)
   und Platzhalter-Screens, die nur den Screen-Namen anzeigen. Slot für einen Mini-Player über der Tab-Leiste vorsehen.
6. Lokalisierung: `lib/l10n/app_de.arb` und `app_en.arb` mit den Tab-Namen; `l10n.yaml`; Systemsprache als Default.
7. `tool/mock_nas/`: kleines Dart-Programm auf Basis von `shelf`, das `/webapi/entry.cgi` bedient und Antworten aus
   `test/fixtures/<api>/<method>.json` liefert. Vorerst nur `SYNO.API.Info query` und `SYNO.API.Auth login/logout`
   mit Beispiel-Fixtures nach Synology-API-Doku. Startbar mit `dart run tool/mock_nas/main.dart --port 5000`.
8. `.github/workflows/ci.yml`: bei Push und PR `flutter pub get`, `dart format --set-exit-if-changed .`,
   `flutter analyze`, `flutter test`, `flutter build apk --debug`. Flutter über subosito/flutter-action, stable, mit Cache.
9. README.md: Was die App ist (aus CONCEPT.md Abschnitt 1), Status "in Entwicklung", Link auf docs/CONCEPT.md,
   Hinweis auf unterstützte DSM-Versionen, Build-Anleitung, Lizenz CC0.
10. `.gitignore` um Keystore-Dateien (*.jks, *.keystore, key.properties), `.env` und `*.pem` ergänzen.

Ein Widget-Test, der die App startet und die vier Tabs findet, muss grün sein.
```

---

## Prompt 1 – M0 Core: Verbindung und Login · Branch `feat/m0-core-auth`

```
Implementiere die Netzwerk- und Auth-Basis aus CONCEPT.md Abschnitt 2, 4 und 5 – ohne UI, aber vollständig getestet.

core/network:
- `SynoApiClient` auf dio: Basis-URL aus einem `ServerProfile` (Name, lanUrl, externalUrl optional, user).
  Verbindungsstrategie: LAN zuerst mit 2 s Timeout, bei Netzwerkfehler (nicht bei HTTP-/API-Fehler) Fallback auf extern.
  Aktive Adresse als Stream nach außen geben.
- `SYNO.API.Info query` beim Verbinden, Ergebnis gecacht; jede API-Anfrage nimmt die vom NAS gemeldete maxVersion.
- SID-Interceptor: `_sid` als Query-Parameter anhängen. Bei API-Fehler 105/106/107/119 genau ein Re-Login, dann Retry, danach Abbruch.
- Fehler-Mapping: Synology-Fehlercodes → `SynoException` (sealed class mit sprechenden Fällen: unauthorized,
  otpRequired, otpInvalid, accountLocked, sessionExpired, permissionDenied, notFound, network, unknown(code)).
- Zertifikat-Pinning: `CertificatePin`-Store (SHA-256-Fingerprint je Host) im Secure Storage. Unbekanntes
  selbstsigniertes Zertifikat → `UntrustedCertificateException` mit Host, Aussteller, Gültigkeit, Fingerprint;
  die UI entscheidet später. Nach Bestätigung wird der Fingerprint gepinnt; abweichender Fingerprint → harter Fehler.
  Niemals `badCertificateCallback = true` global.

core/auth:
- `SessionManager`: login(user, password, otp?) mit `session=FileStation`, `format=sid`, `enable_device_token=yes`,
  `device_name=<Gerätename>`; `did` aus der Antwort speichern und beim nächsten Login als `device_id` mitschicken.
  logout() ruft die API auf und löscht SID/DID. Passwort wird nur gespeichert, wenn `rememberPassword` gesetzt ist.
- Kein Retry bei Auth-Fehlern (Auto-Block).

features/servers/data + domain:
- `ServerProfile` als freezed-Modell, Persistenz in drift (`servers`-Tabelle), Secrets im Secure Storage.
- `ServerRepository`: CRUD + "verbinden".

features/browser/data:
- `FileStationListApi` mit `list_share` und `list` (additional=size,time,type,perm; sort_by, sort_direction, offset, limit).
- Domain-Modell `NasEntry` (path, name, isDir, size, mtime, type-Enum aus Endung, perm).

Mock-Server erweitern: Fixtures für list_share, list (ein Musikordner mit 6 Einträgen wie im Mockup 06), Fehlerfälle
(400 falsches Passwort, 403 OTP nötig, 404 OTP falsch, 119 SID ungültig). Der Mock-Server muss `_sid` prüfen.

Tests: Unit-Tests für Fehler-Mapping, Re-Login-Policy (genau ein Versuch), LAN/extern-Fallback, Device-Token-Flow,
Fingerprint-Pinning; Integrationstest Login → list_share → list gegen den Mock-Server.
```

---

## Prompt 1b – M0 Spike gegen das echte NAS (direkt nach Prompt 1, gleiche Session)

Vorher im Terminal `source ~/.synology-explorer.env` (Datei liegt außerhalb des Repos, enthält NAS_URL, NAS_USER, NAS_PASS, optional NAS_OTP) und dann `claude` starten.

```
Führe den M0-Spike aus CONCEPT.md Abschnitt 10 gegen mein echtes NAS aus. Die Zugangsdaten frage ich dir nicht
in den Chat – lies sie aus Umgebungsvariablen NAS_URL, NAS_USER, NAS_PASS (und NAS_OTP, falls ich sie setze).
Nichts davon darf in Dateien, Logs oder Commits landen.

1. Mit curl gegen `SYNO.API.Info` und `SYNO.API.Auth` prüfen: welche API-Versionen meldet das NAS, funktioniert
   `enable_device_token` und liefert die Antwort ein `did`? Beim zweiten Login mit `device_id` darf kein OTP nötig sein.
2. Eine Audiodatei aus einem Shared Folder per `SYNO.FileStation.Download` mit `mode=open` abrufen. Prüfen, ob das NAS
   HTTP-Range beantwortet: `curl -r 1000-2000` muss 206 Partial Content mit Content-Range liefern. Ergebnis dokumentieren.
3. Prüfen, ob `SYNO.FileStation.Thumb` für eine HEIC-Datei ein JPEG liefert (size=xl) und ob `SYNO.FileStation.Favorite`
   ohne Home-Dienst funktioniert.
4. Echte Antworten von API.Info, list_share, list, getinfo, Thumb-Header als Fixtures unter test/fixtures/ ablegen –
   vorher anonymisieren: Hostnamen, Benutzer, SIDs, DIDs, reale Pfade/Dateinamen durch die Beispielnamen aus
   docs/mockups ersetzen. Fixtures dürfen keine Secrets enthalten.
5. Ergebnisse als docs/SPIKE.md festhalten: DSM-Version, API-Versionen, Range ja/nein, Device-Token ja/nein,
   HEIC-Thumb ja/nein, Favorite ohne Home ja/nein, und welche Annahmen in CONCEPT.md dadurch angepasst werden müssen.
6. Wenn Range nicht funktioniert: in CONCEPT.md Abschnitt 5 den Fallback "Cache-first-Wiedergabe" als Entscheidung eintragen.
```

---

## Prompt 2 – M1 Browsen · Branch `feat/m1-browser`

```
Baue die Screens 01–07 und 09–11 aus docs/CONCEPT.md Abschnitt 7 nach den Mockups in docs/mockups/ (PNGs ansehen!).
Screen 08 (Auswahlmodus) kommt in M4, aber Long-Press soll schon einen Auswahlzustand im Provider setzen.

- 01 Server-Liste, 02 Server hinzufügen/bearbeiten, 03 Zertifikat-Dialog (aus UntrustedCertificateException),
  04 2FA-Code: an SessionManager und ServerRepository aus M0 anbinden. Fehlerzustände aus SynoException im UI abbilden.
- 05 Start: Shared Folders (list_share), Favoriten (lokal in drift), Zuletzt geöffnet (lokal, letzte 50).
- 06 Ordner-Liste mit Breadcrumb, Sortierung (Name/Datum/Größe/Typ, Richtung), Paging über offset/limit (Seiten à 500),
  Pull-to-Refresh, Kebab pro Zeile → 09. FAB vorsehen, aber Aktionen erst in M4.
- 07 Grid-Ansicht mit Thumbnails über SYNO.FileStation.Thumb (eigener ImageProvider, der die SID anhängt, Disk-Cache
  mit Hash-Dateinamen, Standard-Limit 500 MB). Video-Dauer nur anzeigen, wenn im `additional` vorhanden.
- 09 Datei-Aktionen als Bottom Sheet: alle Einträge aus dem Mockup anzeigen; nur Öffnen, Favorit, Info funktionieren
  jetzt, die übrigen sind sichtbar aber deaktiviert mit Tooltip "ab M2/M4".
- 10 Datei-Info mit getinfo; bei Ordnern Button "Größe berechnen" über DirSize (start/status pollen, beim Verlassen stop).
- 11 Suche über SYNO.FileStation.Search (start → list pollen mit Backoff 500 ms–3 s → stop/clean beim Verlassen),
  Typ-Filter-Chips setzen den filetype-Parameter, Treffer-Highlighting wie im Mockup.
- Mini-Player-Slot in der Shell bleibt leer, aber das Layout muss den 64-px-Platz reservieren, sobald ein Provider
  `hasActivePlayback` true meldet.

Mock-Server: Fixtures für Search (start/list/stop), Thumb (ein kleines JPEG), DirSize, getinfo ergänzen.
Tests: Widget-Tests für 02 (Validierung, Fehlerzustände), 05, 06 (Sortierung, Navigation), 11 (Polling stoppt beim
Verlassen). Goldens nicht nötig.
```

---

## Prompt 3 – M2 Audio · Branch `feat/m2-audio`

```
Implementiere die Audio-Wiedergabe aus CONCEPT.md Abschnitt 6 und die Screens 12 (Now Playing), 13 (Queue) sowie den
Mini-Player in der Shell, nach docs/mockups/12.png, 13.png und dem Mini-Player auf 06.png.

- `features/audio`: `PlaybackQueue` (Domain), `AudioController` als Riverpod-Notifier über just_audio + audio_service
  (AudioHandler mit MediaItem, Play/Pause/Skip/Seek, Android-Foreground-Service-Typ mediaPlayback in der Manifest,
  iOS-Background-Mode audio in Info.plist).
- Tippen auf eine Audiodatei in 06 baut die Queue aus allen Audiodateien des Ordners in aktueller Sortierung und startet
  am getippten Index. "Ordner abspielen" aus 09 optional rekursiv (Unterordner via list, max. Tiefe 3).
- Streaming-URL: Download-Endpunkt mit `mode=open` und `_sid`; Range-Requests durch just_audio. Wenn docs/SPIKE.md
  sagt, dass Range nicht funktioniert: Cache-first (Datei in temp laden, dann lokal abspielen) mit Fortschrittsanzeige.
- Resume: Position alle 5 s und bei Pause/Stop in drift (`playback_positions`: path, mtime, positionMs, updatedAt).
  Beim Öffnen derselben Datei Snackbar "Fortsetzen bei mm:ss" mit Aktion. Hörbuch-Modus pro Ordner (Flag in drift):
  zusätzlich letzten Titel merken.
- Cover: 1. ID3-Bild über audio_metadata_reader (aus dem Cache-Prefix der Datei), 2. folder.jpg/cover.jpg im Ordner
  via Thumb, 3. Platzhalter. Cover-Cache mit Schlüssel path+mtime.
- Shuffle, Repeat (aus/Titel/Ordner), Geschwindigkeit 0,8–2,0×, Sleep-Timer (15/30/45/60 min, Ende des Titels).
- Session-Ablauf während der Wiedergabe: vor jedem Titelwechsel gültige SID sicherstellen (SessionManager), sonst Re-Login.
- Netzwechsel: nächster Titel wählt die Adresse neu; Einstellung "Streaming nur im WLAN" respektieren (connectivity_plus).
- 13 Queue: Reorder per Drag-Handle, Wischen entfernt, "Leeren"; aktueller Titel hervorgehoben.

Tests: Unit-Tests für Queue-Aufbau (Sortierung, Startindex, Shuffle-Reproduzierbarkeit mit Seed), Position-Persistenz,
Sleep-Timer, Cover-Fallback-Kette. Widget-Test für 12 und 13 mit gemocktem AudioController.
Hinweis in der Zusammenfassung: Hintergrundwiedergabe, Sperrbildschirm und Bluetooth müssen auf echtem Gerät geprüft werden.
```

**Prompt 3b (echte Geräte, direkt nach Prompt 3):** beide Handys verbinden (`adb devices` zeigt Samsung und OnePlus), dann:
```
Es sind zwei Geräte verbunden: ein älteres Samsung (Referenz für Mindest-API und schwache Hardware) und ein aktuelles
OnePlus (Hauptgerät). Lies die Geräte-IDs und Android-Versionen mit `adb devices -l` und `adb -s <id> shell getprop
ro.build.version.sdk` aus und sprich Geräte immer explizit mit `-d <id>` bzw. `-s <id>` an, nie das "erste".
Installiere ein Debug-Build auf beiden und prüfe mit mir gemeinsam, zuerst auf dem OnePlus, dann auf dem Samsung:
Album-Ordner spielt 15 Minuten im Hintergrund durch, Sperrbildschirm-Steuerung, Kopfhörertaste, Position wird nach
App-Kill wiederhergestellt, Wechsel WLAN→Mobil während der Wiedergabe. Auf dem Samsung zusätzlich: App-Start-Zeit,
Scroll-Flüssigkeit in einem Ordner mit 500+ Einträgen, Akku-Optimierung (Doze) beendet die Wiedergabe nicht.
Fixe, was auffällt, und halte Beobachtungen je Gerät in docs/SPIKE.md fest.
```

---

## Prompt 4 – M3 Viewer · Branch `feat/m3-viewers`

```
Baue die Viewer-Screens 15–19 nach docs/mockups/ und CONCEPT.md Abschnitt 6.

- 15 Bild-Viewer: PageView über alle Bilder des Ordners, photo_view mit Pinch-Zoom, Vorladen des nächsten Bilds,
  Overlay ein-/ausblenden per Tippen, Thumbnail-Streifen unten, Aktionen Teilen (share_plus), In Fotos speichern
  (image_gallery_saver oder aktuelles Äquivalent), Favorit, Löschen (deaktiviert bis M4). HEIC: Anzeige über
  Thumb size=xl; Original nur bei Teilen/Speichern laden. Wenn Thumb fehlschlägt: Original laden und plattformnativ
  dekodieren, ansonsten Platzhalter mit Hinweis "HEIC-Vorschau auf dem NAS nicht verfügbar".
- 16 Video-Player mit media_kit: Landscape-Vollbild, Controls wie im Mockup (±10 s, Seek, Geschwindigkeit,
  Untertitel-Toggle für eingebettete Spuren), Resume-Dialog "Bei mm:ss fortsetzen?", Positions-Speicherung wie Audio.
  Gesten: rechts Lautstärke, links Helligkeit (screen_brightness).
- 17 PDF-Viewer mit pdfrx: Datei erst komplett in den Cache laden (Fortschritt anzeigen), dann rendern; Seiten-Scroll,
  Seitennummer-Eingabe, Text-Suche, Teilen.
- 18 Text/Markdown/Code: bis 5 MB laden, darüber Hinweis + "Öffnen mit". Markdown gerendert mit Umschalter Rohtext,
  Code-Highlighting nach Endung (flutter_highlight oder Äquivalent), Schriftgröße umschaltbar.
- 19 DOCX-Lesemodus: eigener Parser in `features/viewers/docx/` (docx = Zip, `word/document.xml` mit `package:xml`):
  Absätze, Überschriften (Heading-Styles), Fett/Kursiv/Unterstrichen, nummerierte und Aufzählungslisten, einfache
  Tabellen, eingebettete Bilder (word/media). Ausgabe als eigenes Widget-Modell, nicht über HTML. Banner "vereinfachte
  Darstellung", Buttons Herunterladen und "Öffnen mit" (open_filex).
- Generisch: jede unbekannte Datei → Download in Cache → open_filex.
- Cache-Verwaltung in `core/storage/media_cache.dart`: LRU nach Größe, Hash-Dateinamen, Limit aus Einstellungen.

Tests: Unit-Tests für den DOCX-Parser mit drei Test-Dokumenten unter test/fixtures/docx/ (Brief, Protokoll mit Tabelle,
Dokument mit Bild), für die Cache-LRU-Logik und die HEIC-Fallback-Kette. Widget-Tests für 15, 17, 19 mit Fixtures.
```

---

## Prompt 5 – M4 Verwaltung, Transfers, Freigaben, Papierkorb · Branch `feat/m4-management`

```
Baue die Screens 08, 14, 20, 21, 22, 23 und 24 nach docs/mockups/ und CONCEPT.md Abschnitt 3, 4, 8.

Dateiaktionen (features/browser):
- 08 Auswahlmodus per Long-Press, Aktionsleiste Download / Verschieben / Kopieren / Teilen / Löschen.
- 09 alle Einträge aktivieren: Umbenennen (Rename), Verschieben/Kopieren nach … (Ordner-Picker als Sheet, CopyMove
  start/status/stop mit Fortschritt), Löschen (Delete start/status; Bestätigungsdialog; Hinweis, ob der Share einen
  Papierkorb hat), Neuer Ordner (CreateFolder).
- 14 Upload-Menü aus dem FAB: Dateien (file_picker), Fotos/Videos (photo_manager oder image_picker), Kamera, Neuer Ordner;
  Schalter Überschreiben.

Transfers (features/transfers):
- `TransferQueue` persistent in drift (transfers-Tabelle: id, kind, remotePath, localPath, bytesDone, bytesTotal, state,
  error, createdAt). Worker verarbeitet max. 2 parallel. Downloads über Download-Endpunkt mit Range-Resume, Uploads über
  SYNO.FileStation.Upload (multipart, overwrite, create_parents) mit dio-Progress. Pause/Abbruch/Wiederholen.
  Queue überlebt App-Neustart. Benachrichtigung mit Fortschritt (flutter_local_notifications).
- 20 Transfers-Screen mit Tabs Aktiv/Fertig wie im Mockup.
- 21 Offline: "Offline verfügbar halten" aus 09 lädt in das App-Documents-Verzeichnis, Eintrag in drift (offline_files:
  remotePath, localPath, mtime, size). Liste nach Ordner gruppiert, Speicherbalken, Entfernen. Beim Öffnen einer
  Offline-Datei ohne Netz lokal öffnen; bei Netz mtime vergleichen und "Auf dem NAS geändert" anzeigen.

Freigaben (features/sharing):
- 22 Sheet: SYNO.FileStation.Sharing create mit Ablauf (1/7/30 Tage/nie, Default 7) und optionalem Passwort;
  Ergebnis mit Kopieren (nur nach Tipp) und Teilen. Link zeigt auf die externe Adresse des Servers, sonst Hinweis.
- 23 Verwaltung: Sharing list, Badges für Ablauf/Passwort, Löschen, "Aufräumen" für abgelaufene.

Papierkorb (features/browser):
- 24: `#recycle` je Share listen (nur anzeigen, wenn das Listing gelingt), Wiederherstellen = CopyMove an den
  Ursprungspfad (aus dem #recycle-Pfad abgeleitet), Endgültig löschen mit zweiter, roter Bestätigung, "Leeren".

Mock-Server: CopyMove/Delete/DirSize als asynchrone Tasks mit status-Polling simulieren, Upload-Endpunkt, Sharing.
Tests: Unit-Tests für TransferQueue (Resume, Retry, Persistenz, Parallelität), Papierkorb-Pfadableitung, Sharing-Ablauf-
Berechnung. Widget-Tests für 08, 20, 22.
```

---

## Prompt 6 – M5 Auto-Upload, Einstellungen, Release · Branch `feat/m5-release`

```
Schließe v1.0 ab: Screens 25 und 26 nach docs/mockups/, Auto-Upload, Lokalisierung und Release-Workflows.

- 25 Auto-Upload (features/autoupload): Einstellungen in drift (enabled, targetPath, schema JJJJ/MM, wifiOnly,
  includeVideos, chargingOnly). Delta-Erkennung über photo_manager (Asset-IDs + createDate, zuletzt verarbeitete ID
  speichern). Android: workmanager-Periodic-Task (15 min) mit Constraints; iOS: background_fetch opportunistisch,
  zusätzlich Nachholen beim App-Start. Uploads laufen über die TransferQueue aus M4. Status-Karte und Protokoll wie im Mockup.
- 26 Einstellungen: Server verwalten (→01), Freigabelinks (→23), Streaming nur WLAN, Auto-Upload (→25), Wiedergabe,
  Cache-Limit (Slider 200 MB–5 GB), Offline-Speicher (→21), Design System/Hell/Dunkel, Sprache, Über & Lizenzen
  (Paketlizenzen über LicenseRegistry, media_kit/libmpv-Hinweis), "Alle lokalen Daten löschen" mit Bestätigung.
- Lokalisierung vervollständigen: alle Strings in app_de.arb und app_en.arb, keine hartkodierten UI-Texte mehr
  (mit einem Test absichern, der nach Literal-Strings in presentation/ greppt).
- PRIVACY.md auf Basis von CONCEPT.md Abschnitt 8; THIRD_PARTY.md aus den Paketlizenzen generieren (Script in tool/).
- Android: Foreground-Service-Typen mediaPlayback und dataSync in der Manifest, Permissions minimal (Fotos nur bei
  Auto-Upload zur Laufzeit anfragen). iOS: PrivacyInfo.xcprivacy mit den genutzten Reason-APIs, Background Modes audio+fetch.
- `.github/workflows/release-android.yml`: bei Tag v*: Version aus Tag in pubspec (build number = run_number),
  Keystore aus Secret ANDROID_KEYSTORE_BASE64 + KEY_PROPERTIES, `flutter build apk --split-per-abi` und `appbundle`,
  APKs als GitHub-Release-Assets, AAB in den Play-Internal-Track (r0adkll/upload-google-play, Secret PLAY_SERVICE_ACCOUNT_JSON).
- `.github/workflows/release-ios.yml`: macOS-Runner, Fastlane match (Secrets MATCH_GIT_URL, MATCH_PASSWORD,
  APP_STORE_CONNECT_API_KEY), `flutter build ipa`, Upload nach TestFlight. Workflow so schreiben, dass er bei fehlenden
  Secrets sauber mit Hinweis abbricht statt kryptisch zu scheitern.
- release-please konfigurieren (Conventional Commits → CHANGELOG.md und Release-PR).
- README: Screenshots-Platzhalter, Installationswege (GitHub Releases, Play Internal, TestFlight), Einrichtung des
  NAS-Nutzers (File Station zuweisen, vertrauenswürdige Geräte erlauben).

In der Zusammenfassung auflisten, welche Secrets ich in den Repo-Settings anlegen muss.
```

---

## Danach: laufende Arbeit

Für Bugfixes und kleine Features reicht ein kurzer Prompt mit derselben Kopfzeile, z. B.
`Fix: Die Queue verliert beim Netzwechsel den aktuellen Titel (siehe Issue #12). Reproduziere zuerst per Test.`
Für PRs mit CI-Fehlern: `/autofix-pr` auf dem PR-Branch startet eine Cloud-Session, die CI-Fehler und Review-Kommentare selbst nacharbeitet (optional).
