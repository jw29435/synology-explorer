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
| Testordner mit Schreibrecht | gibt es nicht; `CreateFolder` in `/Daten` einmal versuchen (erwartet 407), sonst nur Fehlerpfade |
| Freigabelink | erlaubt (erwartet 407; bei Erfolg sofort löschen) |
| `pm clear` | auf beiden Geräten erlaubt |
| Überspringen | nichts (außer den Sperren aus dem Auftrag: Auto-Upload nie einschalten, Papierkorb nur listen) |
| Release-Build | Keystore liegt als GitHub-Secret; lokal wird versucht, ohne `key.properties` zu bauen |

## Phase 1 – Capabilities des Testkontos (curl, 26.09.2026)

DSM 7.2.1, einziger sichtbarer Share `/Daten` (`share_right: RW`, ACL `read/del/exec: true`, `write/append: false`,
`adv_right` alles `false`, POSIX 555). Testdaten per `Search` gefunden: Audio-Ordner mit 8 MP3 + 3 JPG, Ordner mit
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
| `CreateFolder /Daten/_e2e_<ts>` | **1100 / 407** – kein Testordner | alle Schreibaktionen: nur Fehlerpfad |
| `Upload` in nicht existierenden Ordner | 408 (ohne `create_parents`), 407 (mit) | 14/20: Fehlermeldung, kein Endlos-Retry |
| `Rename` auf nicht existierende Datei im Testordner-Pfad | 1200 / 408 | Fehlermeldung |
| `CopyMove` / `Delete` auf nicht existierende Datei | `start` ok, `status` 599 bzw. `finished` ohne Fehler | Delete kann auf echten Dateien klappen (`del: true`) → nie auf echten Dateien |

Auf dem NAS blieb nach Phase 1 nichts zurück: `/Daten` enthält weiter nur den bisherigen Ordner, die Favoritenliste
ist vor und nach dem Test identisch (drei temporäre `_e2e_…`-Favoriten angelegt und gelöscht), keine Freigabelinks.

## Annahmen

- NAS-Favoriten nur für Ordner: DSM nimmt Dateien als Favorit an, meldet sie aber sofort als `broken`. Die App
  bietet „Favorit“ deshalb nur für Ordner an (DS-File-Verhalten, dort gibt es ebenfalls nur Ordner-Favoriten).
- Markdown-Viewer ist am echten NAS nicht testbar (keine `.md`-Datei); geprüft werden `.txt` und headless Markdown.
