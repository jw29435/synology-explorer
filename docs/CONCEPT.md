# Nuvo Explorer – Konzept v1

Sep 25, 2026 · @Johann

## 1. Ziel und Rahmen

Nuvo Explorer ist ein Flutter-Client für Android und iOS, der Dateien auf einem Synology NAS über die File-Station-API browst, verwaltet und direkt wiedergibt – mit Musik als Kernfunktion. Funktionales Vorbild ist DS File; Optik und Bedienung werden eigenständig entworfen.

| Punkt | Festlegung |
| --- | --- |
| Plattformen | Android (min. API 26 / Android 8), iOS (min. 15). Ein Codebase, Flutter stable |
| Zielgruppe | Nutzer eines eigenen NAS (Familie, KMU), die Musik, Bilder, Videos und Dokumente vom NAS aus konsumieren |
| Backend | Ausschließlich DSM Web API (File Station). Kein eigener Server, keine Cloud, keine Telemetrie |
| Lizenz / Repo | CC0, öffentlich unter `jw29435/synology-explorer` |
| Sprache der App | Deutsch und Englisch ab v1 (ARB-Dateien), Systemsprache als Default |
| Nicht im Scope | Audio Station-, Photos- oder Drive-APIs, Synology Office, Musik-Bibliothek nach Tags, Chromecast/AirPlay, Tablet-Layouts |

Der Musikfokus heißt konkret: Der Player läuft im Hintergrund, ist über Sperrbildschirm und Kopfhörer steuerbar, merkt sich die Position und behandelt jeden Ordner als Wiedergabeliste. Alles andere (PDF, Bilder, Video, Text) ist ein Viewer, kein Editor.

## 2. Randbedingungen

Die wichtigste Randbedingung ist der deaktivierte Home-Dienst: Es gibt keinen persönlichen Ordner, also auch keine Audio-Station-Privatbibliothek, keine Synology-Photos-Personal-Space und kein Drive „Meine Dateien". Die App arbeitet deshalb ausschließlich auf freigegebenen Ordnern (Shared Folders), die der angemeldete Benutzer sehen darf.

**Konsequenzen ohne Home-Dienst**

- Einstiegsseite zeigt die Liste der Shared Folders, keinen „Home"-Eintrag.
- Wiedergabepositionen, Zuletzt-geöffnet und Playlists werden lokal auf dem Gerät gespeichert (SQLite), nicht auf dem NAS.
- Ordner-Favoriten kommen vom NAS (`SYNO.FileStation.Favorite`, funktioniert ohne Home-Dienst, siehe SPIKE.md) – dieselben wie in DS File. Die App spiegelt sie in SQLite (Sofort-Anzeige und offline) und lädt sie beim Öffnen von 05, per Pull-to-Refresh und nach jeder Änderung neu. Datei-Favoriten bleiben lokal: DSM nimmt Dateien zwar an, führt sie aber sofort als `broken`. Beim Update von v1.0 ersetzt der erste Abgleich die bisher lokalen Ordner-Favoriten durch die NAS-Liste (sie werden nicht hochgeladen).
- Auto-Foto-Upload braucht einen vom Nutzer gewählten Zielordner in einem Shared Folder (z. B. `photo/Handy-Johann`).
- Papierkorb ist der Ordner `#recycle` je Shared Folder. Ob er sichtbar ist, entscheidet die Freigabe-Einstellung „Zugriff auf Papierkorb nur für Administratoren". Die App zeigt ihn nur, wenn das Listing erfolgreich ist.

**Verbindungswege** (alle drei werden unterstützt; pro Server eine primäre Adresse und optional eine zweite Adresse für unterwegs)

| Weg | Adresse | TLS | Besonderheit |
| --- | --- | --- | --- |
| LAN | `https://192.168.x.y:5001` oder Hostname | Selbstsigniertes DSM-Zertifikat | Fingerprint beim ersten Verbinden anzeigen und bestätigen lassen (TOFU), danach gepinnt |
| DDNS / Reverse Proxy | `https://nas.example.de` | Let's Encrypt, gültig | Standardweg unterwegs. Port 443, WebSocket nicht nötig |
| VPN / Tailscale | `https://100.x.y.z:5001` oder MagicDNS-Name | Meist selbstsigniert | Aus App-Sicht identisch mit LAN; Tunnel wird außerhalb der App aufgebaut |

Die primäre Adresse kann jeder der drei Wege sein (LAN-IP, DDNS-Domain oder Tailscale-Adresse); für die meisten Nutzer reicht sie allein. Die App probiert beim Start die primäre Adresse mit kurzem Timeout (2 s) und fällt auf die optionale zweite zurück. Welche Adresse aktiv ist (LAN/extern), zeigt die Statusleiste nur, wenn eine zweite Adresse hinterlegt ist. Fehlt beim Eingeben der Port und ist der Host eine IP-Adresse, ein `*.local`-Name oder ein Hostname ohne Punkt, ergänzt die App den DSM-Standardport (`:5001` bei HTTPS, `:5000` bei HTTP); Domains bleiben unverändert. QuickConnect wird bewusst nicht unterstützt: Es gibt keine öffentliche API, die Relay-Auflösung müsste nachgebaut werden und bricht bei jedem DSM-Update.

**Anmeldung**

- Benutzer/Passwort über `SYNO.API.Auth`, Session `FileStation`, Ergebnis ist eine Session-ID (`sid`).
- 2FA (OTP) wird unterstützt; nach erfolgreichem OTP wird ein Geräte-Token (`did`) angefordert, damit der Code nicht bei jeder Anmeldung nötig ist. Voraussetzung: In DSM ist „Vertrauenswürdige Geräte" erlaubt.
- Passwort wird nicht gespeichert, nur `sid` und `did` im Secure Storage. Läuft die `sid` ab, wird einmal neu angemeldet – dafür muss das Passwort dann neu eingegeben werden. Optional (Einstellung): Passwort im Keystore speichern für stille Re-Logins; Default ist aus.

**Annahmen, die du bitte prüfst**

- DSM 7.1 oder neuer. DSM 6 wird nicht getestet; die API-Aufrufe sind weitgehend gleich, aber `SYNO.API.Auth` v6/v7 unterscheidet sich beim Geräte-Token.
- Der NAS-Benutzer hat mindestens Leserechte auf die relevanten Shared Folders und die Anwendung File Station ist ihm zugewiesen.
- Auto-Block in DSM ist aktiv; die App darf bei Login-Fehlern nicht automatisch wiederholen, sonst sperrt sie sich selbst aus.

## 3. Funktionsumfang v1

v1 deckt den vollen DS-File-Umfang ab, priorisiert aber Audio; die Reihenfolge der Meilensteine in Abschnitt 10 folgt dieser Priorität.

| Bereich | Funktionen in v1 | Nicht in v1 |
| --- | --- | --- |
| Server | Mehrere Server-Profile, je eine primäre Adresse und optional eine zweite mit Auto-Fallback, 2FA, Zertifikat-Pinning, Logout | Single Sign-on, LDAP-Besonderheiten |
| Browsen | Shared Folders, Ordnernavigation mit Breadcrumb, Liste/Grid, Sortierung (Name, Datum, Größe, Typ), Pull-to-Refresh, Ordnergröße abfragen, Datei-Infos | Ansicht nach Dateityp über alle Ordner |
| Suche | Name-Suche innerhalb des aktuellen Ordners (rekursiv), Filter nach Typ | Volltextsuche |
| Favoriten / Zuletzt | Ordner-Favoriten des NAS-Kontos (wie DS File), Datei-Favoriten lokal, Zuletzt geöffnet (letzte 50) | Sync von Datei-Favoriten über Geräte |
| Audio | Ordner-Player mit Queue, Shuffle, Repeat, Hintergrundwiedergabe, Sperrbildschirm-/Bluetooth-Steuerung, Resume-Position pro Datei, Sleep-Timer, Cover aus ID3 oder `folder.jpg` | Bibliothek nach Artist/Album, Gapless, Equalizer, Crossfade |
| Bilder | Galerie-Swipe durch den Ordner, Pinch-Zoom, HEIC über NAS-Thumbnail, Teilen/Speichern in Fotos | Bearbeitung, RAW |
| Video | Streaming mit Seek, Landscape, Untertitel-Spur falls eingebettet | Transcoding, Chromecast |
| PDF | Seiten-Scroll, Zoom, Seitensprung, Text-Suche | Annotationen, Formulare |
| Text / Markdown | Anzeige mit Syntax-Highlighting für Code, Markdown gerendert | Editor |
| DOCX | Lesemodus (Absätze, Überschriften, Listen, einfache Tabellen, Bilder) plus „Öffnen mit" | Layouttreue Darstellung, Kommentare, Tracked Changes |
| Andere Dateien | „Öffnen mit" über System-Share-Sheet nach Download | – |
| Verwaltung | Upload (Dateien, Fotos, Kamera), Ordner anlegen, Umbenennen, Kopieren/Verschieben, Löschen, Mehrfachauswahl, Papierkorb anzeigen und wiederherstellen | Rechte bearbeiten, Archiv entpacken |
| Freigaben | Freigabelink erstellen (Ablauf, Passwort), Link kopieren/teilen, eigene Links auflisten und löschen | Datei-Anfragen |
| Transfers | Download-/Upload-Queue mit Fortschritt, Pause/Abbruch, Fortsetzen nach Netzwechsel, Offline-Bereich für heruntergeladene Dateien | Sync-Ordner |
| Auto-Upload | Neue Fotos/Videos aus der Kamera-Rolle in einen Zielordner, nur WLAN optional, Ordnerschema `JJJJ/MM` | iOS-Hintergrund-Upload garantiert (nur opportunistisch) |
| Einstellungen | Server verwalten, Theme (System/hell/dunkel), Cache-Größe, Offline-Speicher leeren, Sprache, Über/Lizenzen | – |

## 4. Synology-API-Mapping

Alles läuft über `/webapi/entry.cgi` mit `api`, `version`, `method` und der `_sid` als Query-Parameter (kein Cookie-Handling nötig). Beim Start fragt die App `SYNO.API.Info` ab und übernimmt die vom NAS gemeldete Maximalversion je API – so bleiben DSM-Versionsunterschiede in einer Stelle.

| Funktion | API | Methode | Hinweis |
| --- | --- | --- | --- |
| API-Versionen ermitteln | `SYNO.API.Info` | `query` | Einmal pro Verbindung, gecacht |
| Login / Logout | `SYNO.API.Auth` | `login`, `logout` | `session=FileStation`, `format=sid`, `otp_code`, `enable_device_token`, `device_name`, `device_id` |
| Shared Folders | `SYNO.FileStation.List` | `list_share` | `additional=real_path,owner,perm,volume_status` |
| Ordnerinhalt | `SYNO.FileStation.List` | `list` | `additional=size,time,type,perm`; `sort_by`, `sort_direction`, `offset`/`limit` für Paging |
| Datei-Infos | `SYNO.FileStation.List` | `getinfo` | Info-Sheet |
| Suche | `SYNO.FileStation.Search` | `start`, `list`, `stop`, `clean` | Asynchron: Task starten, pollen, aufräumen |
| Thumbnails | `SYNO.FileStation.Thumb` | `get` | \`size=small |
| Streaming & Download | `SYNO.FileStation.Download` | `download` | `mode=open` liefert Bytes; HTTP-Range für Seek – Rangeverhalten in Meilenstein 1 mit `curl -r` verifizieren |
| Upload | `SYNO.FileStation.Upload` | `upload` | Multipart, `overwrite`, `create_parents`; große Dateien in einem Request, deshalb Abbruch/Resume nur auf Datei-Ebene |
| Ordner anlegen | `SYNO.FileStation.CreateFolder` | `create` |  |
| Umbenennen | `SYNO.FileStation.Rename` | `rename` |  |
| Kopieren / Verschieben | `SYNO.FileStation.CopyMove` | `start`, `status`, `stop` | Asynchron, Fortschritt pollen |
| Löschen | `SYNO.FileStation.Delete` | `start`, `status`, `stop` | Asynchron; landet im `#recycle`, wenn Papierkorb für den Share aktiv ist |
| Papierkorb | `SYNO.FileStation.List` / `CopyMove` | `list`, `start` | `#recycle` listen; Wiederherstellen = Verschieben zurück. Endgültig löschen = `Delete` im `#recycle` |
| Ordnergröße | `SYNO.FileStation.DirSize` | `start`, `status` | Asynchron |
| Freigabelinks | `SYNO.FileStation.Sharing` | `create`, `list`, `delete`, `getinfo` | `expire_times`, `password`, `date_expired` |
| Favoriten (NAS-seitig) | `SYNO.FileStation.Favorite` | `list`, `add`, `delete` | Nur Ordner. `list` mit `status_filter=all` (`status` valid/broken). Vor `add`/`delete` immer `list` (Zustand bekannt, keine überflüssigen Aufrufe); `add` auf Vorhandenes liefert 800 (= Erfolg), `delete` ohne Favorit ist ein No-op. 105 löst hier keinen Re-Login aus. 105/verweigert → Meldung, Cache unverändert |
| Prüfsumme | `SYNO.FileStation.MD5` | `start`, `status` | Optional für Download-Verifikation |

**Fehlerbehandlung**

- Fehlercodes 105 (keine Berechtigung), 106/107 (Session abgelaufen), 119 (SID ungültig) lösen genau einen Re-Login aus, danach Abbruch mit Meldung.
- Code 400/401/402/403/404 beim Login (falsches Passwort, Konto gesperrt, OTP nötig, OTP falsch) werden als eigene Zustände im Login-Screen dargestellt.
- Asynchrone Tasks (Search, CopyMove, Delete, DirSize) werden mit Backoff gepollt (500 ms bis 3 s) und beim Verlassen des Screens gestoppt.

Synologys File-Station-API-Guide (PDF) ist die Referenz; die Dokumentation zu `enable_device_token` ist dort dünn, das Verhalten mit DSM 7.2 sollte im ersten Spike verifiziert werden.

## 5. Technische Architektur (Flutter)

Feature-first Clean Architecture mit Riverpod als State- und DI-Lösung: Jedes Feature hat `data`, `domain` und `presentation`, geteilte Infrastruktur liegt in `core`. Das ist die Struktur, die sich mit Claude Code am zuverlässigsten in kleinen, testbaren Schritten aufbauen lässt.

**Stack (Paketwahl mit Begründung)**

| Zweck | Paket | Warum |
| --- | --- | --- |
| State / DI | `riverpod` + `riverpod_generator` | Compile-time-sicher, testbar ohne Widget-Tree, gut für Async-Streams (Player, Transfers) |
| Navigation | `go_router` | Deep-Links (Freigabelinks später), typisierte Routen, Shell-Route für Mini-Player |
| HTTP | `dio` | Interceptors (SID anhängen, Re-Login), Cancel-Tokens, Range-Requests, Progress-Callbacks für Upload/Download |
| Modelle | `freezed` + `json_serializable` | Immutable DTOs, Unions für Ergebnis-/Fehlerzustände |
| Lokale DB | `drift` | Typisiertes SQLite für Server-Profile, Favoriten, Wiedergabepositionen, Transfer-Queue, Auto-Upload-Status |
| Secrets | `flutter_secure_storage` | SID, Geräte-Token, optional Passwort im Keystore/Keychain |
| Audio | `just_audio` + `audio_service` | Hintergrundwiedergabe, MediaSession/Now-Playing, Kopfhörer-Tasten, Android-Foreground-Service |
| ID3/Cover | `audio_metadata_reader` | Tags aus heruntergeladenen oder teilweise gestreamten Dateien; prüfen, ob Streaming-Tag-Lesen sauber geht, sonst Cover aus `folder.jpg` |
| Video | `media_kit` | libmpv, deckt MKV/HEVC/AC3 ab, was ExoPlayer/AVPlayer nicht tun. Kostet ca. 20 MB APK; Alternative `video_player` wäre schlanker, aber codec-arm |
| Bilder | `photo_view` + eigener `ImageProvider` mit SID-Header | Zoom, Galerie; HEIC über `Thumb`-API als JPEG |
| PDF | `pdfrx` | Render über PDFium, schnell, Text-Suche, funktioniert auf beiden Plattformen |
| Markdown | `flutter_markdown` | Ausreichend für Notizen/READMEs |
| DOCX | eigener Parser `docx → HTML` + `flutter_widget_from_html` | Es gibt keinen brauchbaren Flutter-DOCX-Renderer; der Parser deckt bewusst nur Absätze, Überschriften, Listen, Fett/Kursiv, einfache Tabellen, Bilder ab |
| Hintergrundjobs | `workmanager` (Android), `background_fetch` (iOS) | Auto-Upload; iOS nur opportunistisch |
| Fotozugriff | `photo_manager` | Kamera-Rolle inkrementell lesen |
| Lokalisierung | `flutter_localizations` + ARB | de/en |

**Schichten**

1. `core/network`: `SynoApiClient` (Dio, Basis-URL-Wahl LAN/extern, SID-Interceptor, Zertifikat-Pinning, Fehler-Mapping auf `SynoException`).
2. `core/auth`: `SessionManager` – Login, OTP, Geräte-Token, Re-Login-Policy, Logout.
3. `features/*/data`: API-Wrapper pro Synology-API (`FileStationListApi`, `FileStationDownloadApi` …) und Repositories, die DTOs in Domain-Modelle mappen.
4. `features/*/domain`: Modelle (`NasEntry`, `Server`, `Transfer`, `PlaybackItem`) und Use-Cases nur dort, wo Logik über ein Repository hinausgeht (z. B. Queue-Aufbau aus Ordner).
5. `features/*/presentation`: Riverpod-Notifier + Screens + Widgets. Keine API-Aufrufe direkt aus Widgets.

**Ordnerstruktur**

```markdown
lib/
  app/            # MaterialApp, Router, Theme, Shell mit Mini-Player
  core/           # network, auth, storage, l10n, utils, errors
  features/
    servers/      # Profile, Login, Zertifikat-Dialog
    browser/      # Shared Folders, Ordnerliste, Suche, Aktionen, Papierkorb
    audio/        # Player, Queue, Now Playing, Positionen
    viewers/      # image, video, pdf, text, docx
    transfers/    # Download-/Upload-Queue, Offline-Bereich
    sharing/      # Freigabelinks
    autoupload/   # Kamera-Rolle → NAS
    settings/
test/             # Unit + Widget-Tests, gespiegelte Struktur
integration_test/ # Login → Browse → Play gegen Mock-Server
```

**Streaming-Kette Audio**: `NasEntry` → signierte URL (`Download?…&_sid=`) → `just_audio` `AudioSource.uri` mit Header → Range-Requests ans NAS. Kein lokaler Proxy nötig. Falls das NAS Range nicht sauber bedient (Spike!), Fallback: Datei in temporären Cache laden und lokal abspielen.

**Tests**: Unit-Tests für Parser, Fehler-Mapping, Queue-Logik, Auto-Upload-Delta; Widget-Tests für Browser und Player; ein Integrationstest gegen einen kleinen Mock-Server (`shelf`), der die File-Station-Antworten aus Fixtures liefert. Kein echter NAS in CI.

## 6. Medienwiedergabe im Detail

**Audio (Kernfunktion)**

- Tippen auf eine Audiodatei baut die Queue aus allen Audiodateien des Ordners in aktueller Sortierung und startet an der getippten Position. Unterordner werden nicht rekursiv aufgenommen (Option „Ordner inkl. Unterordner abspielen" im Kontextmenü).
- Formate: MP3, AAC/M4A, FLAC, OGG/Opus, WAV. Was `just_audio` auf der Plattform nicht dekodiert, wird als „nicht abspielbar" markiert statt still übersprungen.
- Hintergrund: `audio_service` liefert Android-Foreground-Service mit Notification und iOS-Now-Playing; Steuerung über Sperrbildschirm, Bluetooth, Kopfhörertasten, Android-Auto-Basisintegration kommt nicht in v1.
- Position: Alle 5 s und bei Pause/Stop wird die Position pro Datei in SQLite gespeichert; beim Öffnen derselben Datei Angebot „Fortsetzen bei mm:ss". Für Hörbuch-Ordner (Einstellung pro Ordner) wird zusätzlich der zuletzt gespielte Titel gemerkt.
- Mini-Player als persistente Leiste unten in der Shell, Tippen öffnet Now Playing als Vollbild-Sheet. Queue als eigener Screen mit Drag-Reorder und Entfernen.
- Cover: 1. ID3-Bild, 2. `folder.jpg`/`cover.jpg` im Ordner, 3. Platzhalter. Cover werden lokal gecacht (Pfad + mtime als Schlüssel).
- Sleep-Timer (15/30/45/60 min oder Ende des Titels), Wiedergabegeschwindigkeit 0,8–2,0x.
- Netzwechsel WLAN → Mobil: Wiedergabe läuft weiter, Adresse wird beim nächsten Titel neu gewählt. Optional „Streaming nur im WLAN".

**Bilder**

- JPG/PNG/GIF/WebP werden per Download-URL geladen, mit Disk-Cache (max. konfigurierbar, Default 500 MB).
- HEIC: Anzeige über `Thumb?size=xl` (JPEG vom NAS), Original wird nur bei „Speichern"/„Teilen" geladen. Voraussetzung: DSM erzeugt HEIC-Thumbnails; auf DSM 7.2 braucht das das Paket Advanced Media Extensions – prüfen. Fallback ohne Thumbnail: Original laden und plattformnativ dekodieren (Android 10+, iOS ok), Flutters eigener Decoder kann kein HEIC.
- Galerie: Swipe durch alle Bilder des Ordners, Vorladen des nächsten Bilds, Info-Overlay mit Name, Auflösung, Datum.

**Video**

- `media_kit` mit Netzwerk-URL und SID; Seek über Range. Landscape-Vollbild, Doppeltipp ±10 s, Helligkeit/Lautstärke-Gesten, Positions-Resume wie Audio.
- Kein Transcoding: Was das Gerät nicht dekodiert, läuft nicht. libmpv-Software-Decoding fängt viel ab, kostet aber Akku.

**PDF**

- `pdfrx`: Datei wird komplett in den Cache geladen (PDFs sind selten > 100 MB), dann lokal gerendert. Vertikaler Seiten-Scroll, Pinch-Zoom, Seitennummer-Eingabe, Text-Suche.

**Text / Markdown / Code**

- Dateien bis 5 MB werden geladen; darüber Hinweis und „Öffnen mit". Markdown gerendert mit Umschalter auf Rohtext, Code mit Highlighting nach Endung.

**DOCX**

- Ehrliche Einordnung: Eine layouttreue DOCX-Anzeige in Flutter gibt es nicht, und ohne Synology Office gibt es keine serverseitige Konvertierung. Der Lesemodus (eigener Parser, siehe Abschnitt 5) reicht für Briefe, Notizen, Protokolle. Für alles andere „Öffnen mit" (Word, Collabora, WPS).
- Wenn dir das zu dünn ist: Alternative ist ein winziger Container auf dem NAS mit LibreOffice-Headless, der DOCX → PDF konvertiert. Das wäre ein optionales Feature ab v1.3, nicht v1.

**Generisches „Öffnen mit"**

- Jede Datei kann heruntergeladen und über das System-Share-Sheet an andere Apps übergeben werden (`share_plus`, `open_filex`).

## 7. Screen-Katalog v1

26 Screens bzw. Sheets, gruppiert nach Feature; die Nummern entsprechen den Artboards im Mockup-Canvas. Grundgerüst: eine Shell mit vier Tabs unten (Dateien, Offline, Transfers, Einstellungen), darüber der Mini-Player, sobald etwas läuft. Viewer und Now Playing öffnen als Vollbild über der Shell.

| Nr. | Screen | Zweck | Wesentliche Elemente | Kommt von / führt zu |
| --- | --- | --- | --- | --- |
| 01 | Server-Liste | Einstieg, Server wählen | Karte je Server mit Name, aktiver Adresse, Status; Leerzustand mit „Server hinzufügen" | Start → 02, 05 |
| 02 | Server hinzufügen | Verbindung und Login | Adresse, Benutzer, Passwort; Name optional (leer = Host der Adresse); zweite Adresse für unterwegs eingeklappt (optional), Schalter „Passwort merken", Button „Verbinden" | 01 → 03/04 → 05 |
| 03 | Zertifikat bestätigen | TOFU für selbstsignierte Zertifikate | Host, Aussteller, Gültigkeit, SHA-256-Fingerprint, „Vertrauen"/„Abbrechen" | 02 |
| 04 | 2FA-Code | OTP-Eingabe | 6-stelliges Feld, „Dieses Gerät merken", Fehlerzustand | 02 → 05 |
| 05 | Dateien – Start | Shared Folders, Favoriten, Zuletzt | Abschnitte: Freigegebene Ordner (Liste), Favoriten (Chips), Zuletzt geöffnet (Zeilen); Suche-Icon | Tab „Dateien" → 06, 11 |
| 06 | Ordner – Liste | Navigation im Ordner | Breadcrumb, Sortier-/Ansicht-Menü, Zeilen mit Icon/Thumb, Name, Größe, Datum, Kebab; FAB „+"; Mini-Player unten | 05 → 06, 07–10, 12, 15–19 |
| 07 | Ordner – Grid | Bilder-/Video-Ordner | Thumbnails 3-spaltig, Typ-Badge, Dauer bei Video | 06 (Umschalter) |
| 08 | Auswahlmodus | Mehrfachauswahl | Checkboxen, Zähler in App-Bar, Aktionsleiste unten: Download, Verschieben, Kopieren, Teilen, Löschen | 06/07 (Long-Press) |
| 09 | Datei-Aktionen (Sheet) | Kontextmenü einer Datei | Öffnen, Abspielen ab hier, Ordner abspielen, Download, Offline verfügbar, Favorit, Freigabelink, Umbenennen, Verschieben, Kopieren, Info, Löschen | 06 (Kebab) → 10, 22 |
| 10 | Datei-Info (Sheet) | Metadaten | Name, Pfad, Größe, Typ, Erstellt/Geändert, Besitzer, Rechte; bei Ordner: Größe berechnen | 09 |
| 11 | Suche | Suche im aktuellen Ordner | Suchfeld, Typ-Filter-Chips (Audio, Bild, Video, Dokument), Ergebnisliste mit Pfad, Ladezustand während Task | 05/06 |
| 12 | Now Playing | Vollbild-Player | Cover groß, Titel/Artist/Album, Fortschritt mit Zeiten, Play/Pause, Vor/Zurück, Shuffle, Repeat, Geschwindigkeit, Sleep-Timer, Queue-Button | Mini-Player → 13 |
| 13 | Queue | Wiedergabeliste | Aktueller Titel hervorgehoben, Drag-Handle, Wischen zum Entfernen, „Leeren" | 12 |
| 14 | Upload-Menü (Sheet) | FAB-Aktionen | Dateien hochladen, Fotos/Videos, Kamera, Neuer Ordner | 06 (FAB) → 20 |
| 15 | Bild-Viewer | Galerie | Vollbild, Swipe, Zoom, Overlay mit Name und Zähler, Aktionen Teilen/Speichern/Info | 06/07 |
| 16 | Video-Player | Streaming | Landscape, Controls mit Seek, ±10 s, Vollbild, Untertitel-Toggle, Resume-Hinweis | 06/07 |
| 17 | PDF-Viewer | Dokumente | Seiten-Scroll, Seitenzähler, Suche, Zoom, Teilen | 06 |
| 18 | Text/Markdown-Viewer | Text | Gerendert/Roh-Umschalter, Schriftgröße, Teilen | 06 |
| 19 | DOCX-Lesemodus | Word-Dateien | Reflow-Text, Hinweis „vereinfachte Darstellung", Button „Öffnen mit" | 06 |
| 20 | Transfers | Download-/Upload-Queue | Tabs Aktiv/Fertig, Zeile mit Fortschritt, Geschwindigkeit, Pause/Abbrechen, Wiederholen bei Fehler | Tab „Transfers" |
| 21 | Offline | Lokale Kopien | Liste nach Ordner gruppiert, belegter Speicher, Entfernen, Öffnen ohne Netz | Tab „Offline" |
| 22 | Freigabelink erstellen (Sheet) | Link anlegen | Ablaufdatum, Passwort, Ergebnis mit Kopieren/Teilen | 09 |
| 23 | Freigabelinks verwalten | Eigene Links | Liste mit Pfad, Ablauf, Passwort-Badge, Löschen | 26 |
| 24 | Papierkorb | `#recycle` je Share | Auswahl des Shares, Liste, Wiederherstellen, Endgültig löschen | 05 (Menü) |
| 25 | Auto-Upload | Kamera-Rolle → NAS | Schalter, Zielordner-Wahl, Nur WLAN, Ordnerschema, Status letzter Lauf | 26 |
| 26 | Einstellungen | App-Konfiguration | Server verwalten, Auto-Upload, Freigabelinks, Streaming nur WLAN, Cache-Größe, Theme, Sprache, Über | Tab „Einstellungen" → 01, 23, 25 |

Zu 06 gehört der Mini-Player als persistentes Element (Cover klein, Titel, Play/Pause, Weiter), er ist kein eigener Screen und wird auf 06 mitgezeigt. Screen 02 dient auch zum Bearbeiten eines Servers.

## 8. Sicherheit und Datenschutz

Die App speichert keine Daten außerhalb des Geräts und des NAS; es gibt keine Analytics, keine Crash-Reporter mit Upload, keine Drittserver.

- **Transport**: Nur HTTPS. HTTP wird im Formular erlaubt, aber mit rotem Warnhinweis, und die Adresse wird als unsicher markiert. Selbstsignierte Zertifikate werden nach expliziter Bestätigung per Fingerprint gepinnt; ändert sich das Zertifikat, wird die Verbindung geblockt und der Dialog erneut gezeigt. Kein globales „Zertifikatsprüfung aus".
- **Credentials**: Passwort standardmäßig nicht gespeichert. SID und Geräte-Token im Secure Storage (Android Keystore / iOS Keychain). Logout ruft `SYNO.API.Auth logout` auf und löscht lokale Tokens.
- **Auto-Block-freundlich**: Kein automatischer Login-Retry bei Fehlern 400/402; Re-Login nur bei abgelaufener Session, maximal einmal je Request-Kette.
- **Freigabelinks**: Beim Erstellen wird ein Ablaufdatum vorgeschlagen (7 Tage). Links werden nie ohne Bestätigung in die Zwischenablage kopiert.
- **Löschen**: Immer Bestätigungsdialog; Hinweis, ob der Share einen Papierkorb hat (aus `list_share` `additional=perm`, sonst Info-Text). Endgültiges Löschen aus dem Papierkorb hat eine zweite, rot markierte Bestätigung.
- **Cache**: Thumbnails und Medien-Cache liegen im App-eigenen Cache-Verzeichnis, ohne Datei-Namen im Klartext (Hash als Dateiname). Offline-Dateien liegen im App-Documents-Verzeichnis; „Alle Daten löschen" in den Einstellungen entfernt Cache, Offline-Dateien und Tokens.
- **Berechtigungen**: Fotos nur bei Auto-Upload oder „In Fotos speichern"; Benachrichtigungen für Transfers und Player; kein Standort, keine Kontakte.
- **Play/App-Store**: Datenschutzerklärung im Repo (`PRIVACY.md`), die genau das oben beschreibt. Für iOS zusätzlich die Privacy-Manifest-Datei mit den genutzten Reason-APIs (File Timestamp, User Defaults).

## 9. Build, CI/CD und Verteilung

GitHub Actions baut auf jeden Push nach `main` Analyse und Tests, auf jeden Tag `v*` signierte Release-Artefakte für alle drei Kanäle.

| Workflow | Trigger | Schritte | Ergebnis |
| --- | --- | --- | --- |
| `ci.yml` | Push, Pull Request | `flutter analyze`, `flutter test`, Format-Check, Build-Check Android Debug | Status-Badge |
| `release-android.yml` | Tag `v*` | Version aus Tag, Keystore aus Secret, `flutter build apk --split-per-abi` + `appbundle`, Upload auf GitHub Release, AAB zu Play (Internal Track) via `r0adkll/upload-google-play` | APKs + Play-Internal |
| `release-ios.yml` | Tag `v*` | macOS-Runner, Fastlane `match` für Zertifikate, `flutter build ipa`, Upload zu TestFlight via `upload_to_testflight` | TestFlight-Build |

**Signing & Secrets**

- Android: Upload-Keystore einmal erzeugen, Base64 als GitHub-Secret; Play App Signing übernimmt den App-Signing-Key. Der Keystore darf nie ins Repo – `.gitignore` und ein Pre-Commit-Check.
- iOS: Apple Developer Account (99 $/Jahr), App-ID, Fastlane `match` mit einem privaten Zertifikats-Repo, App Store Connect API-Key als Secret.
- Play: Datenschutzerklärung (aus `PRIVACY.md`, per GitHub Pages veröffentlicht), Data-Safety-Formular („keine Daten erhoben"), Foreground-Service-Typ `mediaPlayback` deklarieren, sonst wird das Bundle abgelehnt.

**Versionierung**: SemVer im Tag, `pubspec.yaml` wird im Workflow gesetzt (`version: 1.2.0+<run_number>`). Changelog aus Conventional Commits (`release-please`), das spart Handarbeit.

**Repo-Struktur**

```markdown
synology-explorer/
  README.md          # Was, Screenshots, Installation, unterstützte DSM-Versionen
  CONCEPT.md         # dieses Dokument, exportiert
  PRIVACY.md
  LICENSE            # CC0
  docs/mockups/      # PNG-Export der Artboards
  .github/workflows/
  lib/ test/ integration_test/
  android/ ios/
```

CC0 für den Code ist deine Entscheidung; beachte, dass `media_kit` (libmpv, LGPL) und einige Pakete eigene Lizenzen mitbringen, die im „Über"-Screen und in `THIRD_PARTY.md` genannt werden müssen.

## 10. Roadmap

Fünf Meilensteine, jeder ist für sich installierbar und testbar; Audio ist ab M2 nutzbar, der volle DS-File-Umfang ab M4.

| Meilenstein | Inhalt | Fertig, wenn |
| --- | --- | --- |
| M0 Spike (1 Woche) | Projekt-Skelett, `SynoApiClient`, Login inkl. OTP + Geräte-Token, `list_share`, Range-Streaming einer MP3 verifiziert, Zertifikat-Pinning | Eine MP3 vom NAS spielt per Range-Seek im Debug-Build, CI grün |
| M1 Browsen (2 Wochen) | Screens 01–07, 09–11, Sortierung, Thumbnails, Suche, Favoriten/Zuletzt lokal | Alle Shares navigierbar, Suche liefert Treffer, Widget-Tests für Browser |
| M2 Audio (2 Wochen) | Screens 12, 13, Mini-Player, Hintergrund, Sperrbildschirm, Resume, Sleep-Timer, Cover | Album-Ordner läuft eine Stunde im Hintergrund durch, Positionen werden gemerkt, Android + iOS |
| M3 Viewer (2 Wochen) | Screens 15–19, „Öffnen mit", Cache | Alle Zielformate öffnen; HEIC via Thumb bestätigt; DOCX-Lesemodus mit 3 Testdokumenten |
| M4 Verwaltung & Transfers (3 Wochen) | Screens 08, 14, 20–24, Upload, Move/Copy/Delete, Freigabelinks, Papierkorb, Offline | Jede Aktion gegen echtes NAS getestet, Transfer-Queue überlebt App-Neustart |
| M5 Auto-Upload & Release (2 Wochen) | Screens 25, 26, Auto-Upload, Lokalisierung, Release-Workflows, Store-Listings | v1.0 auf GitHub Releases, Play Internal, TestFlight |

Danach: v1.1 Bibliotheksansicht (Artist/Album aus Tags), v1.2 Tablet-Layout, v1.3 optionaler DOCX→PDF-Konverter als NAS-Container, Chromecast.

## 11. Risiken, Stolperfallen und offene Punkte

Die drei Punkte mit dem größten Einfluss auf den Aufwand sind Range-Streaming, iOS-Hintergrundverhalten und DOCX – alle drei werden in M0 bzw. M3 früh geprüft.

| Risiko | Auswirkung | Gegenmaßnahme |
| --- | --- | --- |
| `Download` bedient HTTP-Range nicht sauber | Kein Seek beim Streaming | M0-Spike; Fallback Cache-first-Wiedergabe |
| Geräte-Token (`enable_device_token`) funktioniert bei DSM-Version anders | OTP bei jedem Login | Spike; Fallback „Passwort merken" + OTP-Dialog |
| Session läuft während Hintergrundwiedergabe ab | Nächster Titel bricht ab | Re-Login im Interceptor; nächster Titel erst nach gültiger SID starten |
| HEIC-Thumbnails werden vom NAS nicht erzeugt | HEIC nicht anzeigbar | Original laden, nativ dekodieren; Hinweis auf Advanced Media Extensions |
| DOCX-Darstellung enttäuscht | Feature wirkt halbfertig | Klar als Lesemodus kommunizieren; „Öffnen mit" prominent; v1.3-Konverter |
| iOS killt Hintergrund-Upload | Auto-Upload unzuverlässig auf iPhone | Beim App-Start nachholen, Status transparent anzeigen |
| `media_kit` bläht APK auf | \~20 MB mehr | Akzeptieren; Alternative `video_player` nur wenn Codec-Abdeckung reicht |
| Auto-Block sperrt Nutzer bei Adresswechsel-Retry | Nutzer ausgesperrt | Kein Retry bei Auth-Fehlern; Fallback-Adresse nur bei Netzwerkfehler |
| Große Ordner (> 5.000 Einträge) | Träges Listing | Paging über `offset/limit`, Lazy-List, Thumbnails erst im Viewport |
| Papierkorb nur für Admins sichtbar | Screen 24 leer | Screen nur anzeigen, wenn `#recycle` listbar |
| Play-Review: Foreground-Service, Fotozugriff | Ablehnung | Service-Typ deklarieren, Fotozugriff nur bei Auto-Upload, Erklärvideo für Review |

**Offene Punkte, die du entscheiden solltest**

- [ ] Welche DSM-Version läuft auf dem Ziel-NAS? (bestimmt API-Versionen und Geräte-Token-Verhalten)
- [ ] Ist 2FA auf dem Konto aktiv, und sind vertrauenswürdige Geräte erlaubt?
- [ ] Sind HEIC-Thumbnails auf dem NAS bereits sichtbar (z. B. in File Station)?
- [ ] Reicht der DOCX-Lesemodus, oder soll der Konverter-Container früher kommen?
- [x] App-Name für die Stores: der bisherige Name enthielt die fremde Marke „Synology" – für Play/App Store ist ein neutraler Name sicherer. Entscheidung: **„Nuvo Explorer"** (Paket-ID `de.jw29435.nuvo_explorer`, iOS `de.jw29435.nuvoExplorer`).
- [ ] Farbwelt und Icon: Die Mockups nutzen eine dunkle Basis mit Akzentfarbe; bitte in den Mockups kommentieren.
