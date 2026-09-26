# E2E-Findings v1

Gesammelt im E2E-Lauf (`docs/E2E-RUN.md`): statisches Audit (Phase 2, Agents A Navigation, B Screens/Mockups,
C Fehlerpfade, D Hygiene/Sicherheit), headless E2E gegen den Mock-NAS (Phase 3, Quelle H), Gerät gegen das echte NAS
(Phase 4, Quelle G). Dubletten sind zusammengeführt (Spalte „Quelle“).

Schweregrad: crash > blockiert > sicherheit > navigation > fehlermeldung > kosmetik („sicherheit“ ist eine
Ergänzung zur vorgegebenen Skala, siehe Annahmen in E2E-RUN.md). Status: offen / behoben (Commit) / wontfix (Grund).

| ID | Schwere | Screen | Datei:Zeile | Beschreibung | Repro | Quelle | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E2E-001 | blockiert | 01/20/21/26 | lib/features/servers/presentation/server_list_screen.dart:138 | Ohne Session führt kein Weg in die Shell: Offline, Transfers und Einstellungen sind unerreichbar, obwohl der Router sie ohne Session erlaubt und Offline-Dateien ohne Netz öffnen können soll. | Flugmodus oder abmelden, App starten: nur Server-Liste | A-003, B-001 | offen |
| E2E-002 | blockiert | 24 | lib/features/browser/presentation/trash_screen.dart:37 | Scheitert `sharesProvider`, bleibt „Prüfe Papierkörbe …“ für immer stehen – kein Fehler, kein Neuversuch. | Netz weg, Papierkorb öffnen | C-010, B-005 | offen |
| E2E-003 | blockiert | 15 | lib/features/viewers/presentation/image_viewer_screen.dart:387 | „Löschen“ im Bild-Viewer dauerhaft deaktiviert mit Tooltip „ab M4“, obwohl Löschen existiert. | Bild öffnen, Löschen tippen | B-002 | offen |
| E2E-004 | blockiert | 19 | lib/features/viewers/presentation/docx_viewer_screen.dart:86 | „Herunterladen“ im DOCX-Lesemodus dauerhaft deaktiviert („ab M4“). | DOCX öffnen, Herunterladen | B-003 | offen |
| E2E-005 | sicherheit | – | android/app/src/main/AndroidManifest.xml:31 | Kein `allowBackup="false"`/`dataExtractionRules`: DB (Server, Pfade), Offline-Dateien und Secure-Storage-Prefs gehen ins Android-Backup; widerspricht PRIVACY.md. | `adb shell bmgr backupnow …` | D-001 | offen |
| E2E-006 | sicherheit | – | lib/core/network/syno_exception.dart:87 | `SynoNetworkError.toString()` gibt `cause` aus; eine dart:io-`HttpException` enthält die URL mit `_sid`. Unbehandelte Fehler landen so samt SID im Log. | Unit-Test mit `HttpException(uri: …?_sid=S)` | D-003 | offen |
| E2E-007 | sicherheit | 01 | lib/features/servers/data/server_repository.dart:36 | „Server löschen“ lässt Transfers, Offline-Dateien (DB + Platte), Wiedergabepositionen, Hörbuch-Ordner und eine Auto-Upload-Konfiguration mit der alten `serverId` zurück. | Server mit Offline-Datei löschen, Tab Offline | D-004 | offen |
| E2E-008 | sicherheit | 21 | lib/features/transfers/presentation/transfer_providers.dart:21 | iOS: Offline-Dateien ohne `NSURLIsExcludedFromBackupKey` → iCloud-Backup. | iOS, Offline-Datei, iCloud-Backup | D-002 | offen |
| E2E-009 | navigation | 26 → 01 | lib/features/settings/presentation/settings_screen.dart:105 | „Server verwalten“ springt per `go('/servers')` aus der Shell: Screen 01 hat keinen Zurückknopf, Zurück-Geste schließt die App, Tab-Stacks sind weg (**bekanntes Beispiel des Nutzers**). | Einstellungen → Server verwalten → Zurück | A-001 | offen |
| E2E-010 | navigation | 05 → 01 | lib/features/browser/presentation/start_screen.dart:71 | „Server wechseln“ auf 05 dasselbe: kein Zurück, Ordner-Stack verloren. | Dateien → Server-Icon → Zurück | A-002 | offen |
| E2E-011 | navigation | 01/12 | lib/features/servers/presentation/server_list_screen.dart:131 | Auf 01 (außerhalb der Shell) kein Mini-Player: laufende Wiedergabe nur noch über die Notification bedienbar. | Musik starten, Server verwalten | A-012 | offen |
| E2E-012 | navigation | 05–24 | lib/core/auth/session_manager.dart:112 | Scheitert der Re-Login, bleibt `sessionProvider` gesetzt; keine Rückkehr zu 01, Meldung nur lokal (Suche, DirSize, Snackbars ohne Weg zur Anmeldung). | Mock: `list` → 119, Passwort nicht gemerkt | C-001 | offen |
| E2E-013 | navigation | 06/15–19/23/24 | lib/features/browser/presentation/entry_widgets.dart:212 | „Anmelden“ im ErrorPanel springt per `go('/servers/$id')` heraus: Stack verloren, nach Login immer Dateien-Start. | Session ablaufen lassen, Anmelden, Zurück | A-006 | offen |
| E2E-014 | navigation | 01 | lib/features/servers/presentation/server_list_screen.dart:25 | Tipp auf die Karte des aktiven Servers prüft `isLoggedIn` nicht: nach gescheitertem Re-Login wieder Fehlerseite statt Formular. | wie E2E-012, dann Server wechseln, Karte tippen | C-002 | offen |
| E2E-015 | navigation | 08/09/14 | lib/features/browser/presentation/file_actions.dart:19 | Snackbars mit Aktion („Transfers“) bleiben dauerhaft stehen und ihre Aktion nutzt einen oft schon entfernten Context → Exception, keine Navigation. | Auswahl → Download → „Transfers“ in der Snackbar | A-004, A-005, C-017 | offen |
| E2E-016 | navigation | 17 | lib/features/viewers/presentation/pdf_viewer_screen.dart:64 | PDF-Suche: Zurück-Geste schließt den ganzen Viewer statt nur die Suche (kein PopScope). | PDF → Suche → Zurück-Geste | A-007, B-017 | offen |
| E2E-017 | navigation | 06/11 | lib/features/browser/presentation/folder_screen.dart:324 | Breadcrumb-Tipp nutzt `go()`: Stack wird [Start, Ziel], Suche und Zwischenordner fallen weg. | Suche → Treffer → Breadcrumb → Zurück | A-008 | offen |
| E2E-018 | navigation | 08/09 | lib/features/browser/presentation/file_actions.dart:357 | Ordner-Picker: Zurück-Geste schließt den ganzen Picker statt eine Ebene hoch. | Verschieben → Unterordner → Zurück-Geste | A-009 | offen |
| E2E-019 | navigation | 05 | lib/features/browser/presentation/start_screen.dart:163 | „Zuletzt geöffnet“ (und Datei-Favoriten, Z. 139) öffnen den Elternordner statt der Datei. | Datei öffnen, zurück, Zuletzt antippen | B-008 | offen |
| E2E-020 | navigation | 11 | lib/features/browser/presentation/search_screen.dart:196 | Datei-Treffer öffnet nur den Elternordner, nicht die Datei. | Suche → Datei-Treffer | B-009 | offen |
| E2E-021 | navigation | 07 | lib/features/browser/presentation/folder_screen.dart:550 | Grid-Kachel ohne Kebab: Sheet 09 (Info, Umbenennen, Favorit …) im Grid unerreichbar. | Grid → Datei-Info versuchen | B-010 | offen |
| E2E-022 | navigation | 01 | lib/features/servers/presentation/server_list_screen.dart:167 | Bearbeiten/Abmelden/Löschen eines Servers nur per Long-Press, ohne sichtbaren Hinweis. | Server-Liste ansehen | B-018 | offen |
| E2E-023 | navigation | 02 | lib/features/servers/presentation/server_form_screen.dart:106 | Bearbeiten des aktiven Servers schließt die Session vor dem Login; scheitert er, ist die gültige Session weg (Musik aus). | Bearbeiten, falsches Passwort | C-013 | offen |
| E2E-024 | fehlermeldung | 06/07/11 | lib/core/network/syno_exception.dart:11 | 105 („keine Berechtigung“) löst Re-Login aus; ohne gemerktes Passwort wird der Nutzer faktisch abgemeldet und sieht „Sitzung abgelaufen“. | Mock: `list` → 105 | C-003 | offen |
| E2E-025 | fehlermeldung | 06/07 | lib/features/browser/presentation/folder_screen.dart:157 | Refresh-/Sortierfehler nach erstem Laden unsichtbar: alte Liste bleibt ohne Hinweis. | Ordner laden, Netz weg, Pull-to-Refresh | C-004 | offen |
| E2E-026 | fehlermeldung | 15/17–20 | lib/core/network/syno_api_client.dart:307 | Download einer gelöschten Datei (DSM: HTTP 502 HTML) erscheint als „HTTP 502“ mit sinnlosem „Erneut versuchen“. | Datei auf NAS löschen, in App öffnen | C-005 | offen |
| E2E-027 | fehlermeldung | 16 | lib/features/viewers/presentation/video_player_screen.dart:101 | Video: jeder Fehler wird zu „kann nicht abgespielt werden“, ohne Erneut/Anmelden. | Mock: Download → 119 | C-006 | offen |
| E2E-028 | fehlermeldung | 16 | lib/features/viewers/presentation/video_player_screen.dart:103 | Video: Fehler nach Start verworfen – bei Netzabbruch Standbild ohne Hinweis, kein Neuladen. | Video, WLAN aus | C-007 | offen |
| E2E-029 | fehlermeldung | 24/08/09 | lib/features/browser/presentation/browser_providers.dart:345 | `recycleBinProvider` macht aus Netz-/Sessionfehlern „nur für Admins sichtbar“. | Mock: `#recycle` → 119 | C-011 | offen |
| E2E-030 | fehlermeldung | 08/09/24 | lib/features/browser/presentation/file_actions.dart:272 | Fortschrittsdialog ohne PopScope: Zurück bricht Verschieben/Löschen still und ggf. teilweise ab. | Löschen, Zurück während Dialog | C-012 | offen |
| E2E-031 | fehlermeldung | 06 | lib/features/audio/presentation/audio_widgets.dart:158 | Mini-Player zeigt Wiedergabefehler nicht an. | Titelwechsel ohne Netz | C-014 | offen |
| E2E-032 | fehlermeldung | 12 | lib/core/utils/format.dart:45 | `describeError` kennt `UntrustedCertificateException` nicht → „Unerwarteter Fehler“. | Adresswechsel auf ungepinntes Zertifikat | C-016 | offen |
| E2E-033 | fehlermeldung | 18 | lib/features/viewers/presentation/text_viewer_screen.dart:189 | FutureBuilder ohne Fehlerzweig: endloser Spinner, wenn die Datei nicht lesbar ist. | Offline-Text mit fehlender Datei | B-004, C-018 | offen |
| E2E-034 | fehlermeldung | 02 | lib/features/servers/presentation/server_form_screen.dart:48 | Bearbeiten: „Passwort merken“ nicht vorbelegt, Speichern löscht das gemerkte Passwort still. | Server mit gemerktem Passwort bearbeiten | B-006 | offen |
| E2E-035 | fehlermeldung | 23 | lib/features/sharing/presentation/share_links_screen.dart:83 | Link löschen und „Aufräumen“ ohne Bestätigung (CONCEPT 8 verlangt sie). | Mülleimer tippen | B-007 | offen |
| E2E-036 | fehlermeldung | 06/14 | lib/features/browser/presentation/upload_sheet.dart:40 | Nach fertigem Upload wird der Ordner nicht neu geladen. | Upload, im Ordner bleiben | B-011 | offen |
| E2E-037 | fehlermeldung | 01 | lib/features/servers/presentation/server_list_screen.dart:124 | Startspinner ohne Text/Abbrechen bis zu 15 s bei unerreichbarem NAS. | NAS unerreichbar, App starten | B-012 | offen |
| E2E-038 | fehlermeldung | 05 | lib/features/browser/presentation/start_screen.dart:86 | Leere Share-Liste ohne Leerzustand/Hinweis. | Konto ohne Shares | B-013 | offen |
| E2E-039 | fehlermeldung | 01 | lib/features/servers/presentation/server_list_screen.dart:127 | DB-Fehler bei `serversProvider` erscheint als „keine Server“. | serversProvider wirft | B-014 | offen |
| E2E-040 | fehlermeldung | 24 | lib/features/browser/presentation/trash_screen.dart:146 | Papierkorb zeigt nur die erste Seite (500). | > 500 Einträge in `#recycle` | B-015 | offen |
| E2E-041 | fehlermeldung | 16 | lib/features/viewers/presentation/video_player_screen.dart:228 | Video ohne Lade-/Pufferanzeige (schwarzes Bild). | Großes Video, langsames Netz | B-016 | offen |
| E2E-042 | kosmetik | 15–19 | lib/features/viewers/presentation/viewer_screen.dart:79 | Ladezustand des Viewers ohne AppBar/Zurückknopf. | Viewer aus „Zuletzt“, langsames NAS | A-010 | offen |
| E2E-043 | kosmetik | 15 | lib/features/viewers/presentation/image_viewer_screen.dart:129 | Bild-Viewer zeigt während des Ordner-Ladens keinen Zurückknopf. | Bild bei langsamem Netz | A-011 | offen |
| E2E-044 | kosmetik | 16 | lib/features/viewers/presentation/video_player_screen.dart:64 | Video pausiert beim App-Wechsel nicht, Ton läuft ohne Bedienung im Hintergrund weiter. | Video, Home | C-008 | offen |
| E2E-045 | kosmetik | 16/12 | lib/features/viewers/presentation/video_player_screen.dart:108 | Videostart pausiert laufende Musik nicht. | Musik, dann Video | C-009 | offen |
| E2E-046 | kosmetik | 21/12 | lib/features/audio/presentation/playback_providers.dart:223 | Anmelden beendet eine laufende Offline-Wiedergabe. | Offline-MP3, dann anmelden | C-015 | offen |
| E2E-047 | kosmetik | 15/16 | lib/features/viewers/presentation/image_viewer_screen.dart:224 | Design „Hell“: Viewer-Overlay (Titel, Aktionen) dunkel auf dunkel. | Hell, Bild öffnen | B-019 | offen |
| E2E-048 | kosmetik | 07 | lib/features/browser/presentation/folder_screen.dart:564 | Design „Hell“: Play-Icon auf Video-Kacheln unsichtbar. | Hell, Grid mit Video | B-020 | offen |
| E2E-049 | kosmetik | 07 | lib/features/browser/presentation/folder_screen.dart:557 | Grid: Typ-Badge nur bei HEIC, keine Videodauer (Katalog 07). | Grid mit mp4/jpg | B-021 | offen |
| E2E-050 | kosmetik | 10 | lib/features/browser/presentation/entry_sheets.dart:300 | Info-Sheet ohne Zeile „Typ“. | Datei → Info | B-022 | offen |
| E2E-051 | kosmetik | 05 | lib/features/browser/presentation/start_screen.dart:40 | Statuszeile/Servername ohne Ellipsis → Overflow bei langen Namen. | langer Server-/Benutzername | B-023 | offen |
| E2E-052 | kosmetik | 16 | lib/features/viewers/presentation/video_player_screen.dart:480 | Resume-Karte läuft im Hochformat über. | Video mit Position, Portrait | B-024 | offen |
| E2E-053 | kosmetik | 06 | lib/features/browser/presentation/folder_screen.dart:321 | Breadcrumb-Touch-Ziel ~20 px statt ≥ 44 px. | Breadcrumb tippen | B-025 | offen |
| E2E-054 | kosmetik | 11 | lib/features/browser/presentation/search_screen.dart:97 | „Ganzes NAS“ Touch-Ziel < 44 px. | Suche aus Ordner | B-026 | offen |
| E2E-055 | kosmetik | 21 | lib/features/transfers/presentation/offline_screen.dart:277 | „Auf dem NAS geändert – aktualisieren?“ Touch-Ziel < 44 px. | geänderte Offline-Datei | B-027 | offen |
| E2E-056 | kosmetik | – | .gitignore | `.e2e/` nicht ignoriert. | – | D-005 | behoben (dieser Branch) |

## Testabdeckung (D)

Ohne Widget-Test laut DoD: 01 (nur Leerzustand), 03 Zertifikat-Sheet, 14 Upload-Sheet, 16 Video, 23 Freigabelinks,
24 Papierkorb, `viewer_screen.dart`. Ausgangslage: `flutter analyze` sauber, `dart format` sauber, 278 Tests grün.
