# M0-Spike gegen das echte NAS

Stand 25.09.2026, per curl, Zugangsdaten aus Umgebungsvariablen. Anonymisierte echte Antworten liegen unter
`test/fixtures/dsm-7.2.1/`; `test/features/browser/dsm_fixtures_test.dart` parst sie.

## Ergebnis auf einen Blick

| Frage | Ergebnis |
| --- | --- |
| DSM-Version | DSM 7.2.1-69057 Update 12 (RS2418+) |
| Zugang | HTTPS mit öffentlich gültigem Zertifikat (kein Pinning nötig), Login meldet `is_portal_port: true` |
| Geräte-Token | **ja**, heißt in DSM 7 aber `device_id` (nicht `did`), 86 Zeichen, kommt auch ohne 2FA |
| Zweiter Login mit `device_id` | **ja**, erfolgreich, gleiche `device_id` zurück. OTP-Pfad nicht testbar: 2FA ist auf dem Konto aus |
| HTTP-Range beim Download | **ja**, `206 Partial Content` mit `Content-Range` |
| HEIC-Thumb (`size=xl`) | **nein**: `size=xl` liefert immer 404. **Korrektur M1:** `size=small` funktioniert (siehe „Nachtrag M1“). HEIC-Dateien gibt es im Share keine |
| Favorite ohne Home-Dienst | **ja**: `list` liefert die bestehenden Favoriten, `add`/`delete` funktionieren |

## API-Versionen (`SYNO.API.Info`, alle über `entry.cgi`)

| API | min | max |
| --- | --- | --- |
| SYNO.API.Auth | 1 | 7 |
| SYNO.API.Info | 1 | 1 |
| SYNO.FileStation.List, Download, Favorite, Search, DirSize, Info, MD5, Rename, CreateFolder, Delete | 1 | 2 |
| SYNO.FileStation.Thumb, CopyMove, Sharing | 1 | 3 |
| SYNO.FileStation.Upload | 2 | 3 |

Insgesamt meldet das NAS 818 APIs. Upload v1 wird nicht mehr angeboten; der Client nimmt ohnehin maxVersion.

## Anmeldung

- Login (`session=FileStation`, `format=sid`, `enable_device_token=yes`, `device_name`) liefert
  `account, device_id, ik_message, is_portal_port, sid, synotoken`, **kein `did`**.
- Folge im Code: `SessionManager` speichert jetzt `device_id` (Fallback `did` für DSM 6). Vorher wäre der Token nie
  gespeichert worden. Mock-Fixture `SYNO.API.Auth/login.json` entspricht jetzt der DSM-7-Form.
- Offen: Verhalten mit aktiver 2FA (Login mit OTP → `device_id` → nächster Login ohne OTP). Braucht ein Konto mit 2FA.

## Download und Range (`SYNO.FileStation.Download`, v2, `mode=open`, MP3 mit 15 029 063 Byte)

| Anfrage | Status | Antwort-Header |
| --- | --- | --- |
| `Range: bytes=1000-2000` | 206 | `Content-Range: bytes 1000-2000/15029063`, `Content-Length: 1001`, `Accept-Ranges: bytes`, `Content-Type: audio/mpeg` |
| `Range: bytes=1000-` | 206 | `Content-Range: bytes 1000-15029062/15029063` |
| `Range: bytes=0-0` | 206 | `Content-Range: bytes 0-0/15029063` |

`path` funktioniert als roher String und als JSON-Array. Damit ist das direkte Streaming mit `just_audio` (Seek per Range)
möglich; der Fallback „Cache-first-Wiedergabe" wird **nicht** gebraucht.

## List, getinfo

- `list` nimmt `folder_path` als rohen String und `additional` als JSON-Array (`["size","time","type","perm"]`), wie
  der Client es schickt. `getinfo` nimmt `path` als JSON-Array.
- Rechte: Der Share meldet `share_right: "RW"`, die ACL von Share **und** Dateien aber `write: false` (bei `del: true`,
  POSIX 775). `NasPerm` aus `acl.write` ist für Dateien deshalb vermutlich zu pessimistisch; in M4 mit einem echten
  Schreibversuch klären.

## Thumb

Für ein JPG liefert `SYNO.FileStation.Thumb` mit `size=xl` in v1, v2 und v3, als GET und POST, mit rohem und
JSON-Pfad immer **HTTP 404 mit HTML-Seite** (Header siehe `test/fixtures/dsm-7.2.1/SYNO.FileStation.Thumb/`). Download
derselben Datei in derselben Session funktioniert.

**Ursache geklärt:** Auch die File-Station-Weboberfläche zeigt keine Vorschaubilder. Das NAS erzeugt keine Thumbnails;
es liegt nicht am Portal-Port. Vermutlich ist die Thumbnail-Erzeugung des Indexierungsdienstes für diese Ordner aus –
das ist eine NAS-Einstellung, auf die sich die App nicht verlassen kann.

Folgen:

- **Screen 07 (Grid, M1):** `Thumb` bleibt der erste Weg, aber bei 404 muss die App selbst verkleinern: Original per
  Download laden, mit `cacheWidth`/`ResizeImage` dekodieren, Ergebnis als kleines JPEG im Thumbnail-Cache ablegen. Nur
  im Viewport und mit begrenzter Parallelität, sonst lädt ein Foto-Ordner Hunderte MB.
- **Videos im Grid:** ohne Thumb kein Standbild; Typ-Icon als Platzhalter.
- **HEIC (M3):** Der Weg „Anzeige über `Thumb?size=xl`" fällt auf diesem NAS komplett aus. Es bleibt nur der in
  CONCEPT.md schon genannte Fallback: Original laden und plattformnativ dekodieren (Android 10+, iOS).

## Search

- Der erste `list`-Poll nach `start` meldet oft `finished: true` **ohne** `total`. Das ist ein Zwischenzustand, kein
  Ergebnis. Fertig ist die Suche erst bei `finished: true` **und** vorhandenem `total` – sonst liefert die Suche
  scheinbar 0 Treffer. Wichtig für Screen 11 in M1.
- `extension=mp3` über den ganzen Share: 26 083 Treffer nach ca. 12 s. `extension=jpg` war nach 180 s noch ohne `total`.

## Favorite

- `list` funktioniert ohne Home-Dienst und liefert bestehende Favoriten.
- `add` auf einen schon vorhandenen Favoriten liefert Fehler **800**; `delete` entfernt einen Favoriten auch dann.
  Beim Spike wurde dadurch ein bestehender Favorit gelöscht und anschließend mit gleichem Namen wiederhergestellt.
  Lehre für M1: Favoriten-Aktionen nur auf Pfade anwenden, deren Zustand vorher per `list` bekannt ist.

## Nötige Anpassungen in CONCEPT.md

- Abschnitt 2 „Anmeldung": Der Geräte-Token heißt in DSM 7 `device_id` und wird auch ohne 2FA ausgegeben.
- Abschnitt 2 „Konsequenzen ohne Home-Dienst": NAS-seitige Favoriten funktionieren ohne Home; lokale Favoriten sind
  nicht zwingend. Entscheidung offen (NAS-Favoriten würden sich zwischen Geräten und mit DS File teilen).
- Abschnitt 4: Range verifiziert (Hinweis „in Meilenstein 1 mit curl -r verifizieren" erledigt). Search-Polling-
  Bedingung wie oben ergänzen. Thumb als offenen Punkt markieren.
- Abschnitt 5 „Streaming-Kette Audio" und Abschnitt 11 „Download bedient HTTP-Range nicht": Risiko entfällt, kein
  Cache-first-Fallback nötig.
- Abschnitt 6 „Bilder" und Abschnitt 7 Screen 07: Thumbnails sind nicht garantiert; clientseitiges Verkleinern nach
  Download als Fallback festhalten, HEIC-Anzeige über natives Dekodieren des Originals statt über Thumb.
- Abschnitt 11 „HEIC-Thumbnails werden vom NAS nicht erzeugt": Risiko ist eingetreten und betrifft alle Bildtypen,
  nicht nur HEIC.
- Abschnitt 11 „Offene Punkte": DSM-Version ist 7.2.1; 2FA ist auf dem Konto nicht aktiv.

## Nachtrag M1 (26.09.2026)

Beim Bau von Screen 07 und 11 erneut gegen das NAS geprüft (curl und App auf beiden Handys).

- **Thumb geht doch – nur nicht mit `xl`.** `size=small` liefert für JPGs ein echtes 160×160-JPEG, für manche Dateien
  ein anderes kleines Format (z. B. BMP). `size=medium` liefert teils das **Original** (mehrere MB), `size=xl` immer
  404. Die App fragt deshalb `small` an und fällt bei Fehlern auf Typ-Icons zurück. Der oben beschriebene Befund
  „keine Vorschaubilder“ galt nur für `xl`. Nebenwirkung: Thumb-Anfragen ändern die `mtime` des Ordners (DSM legt
  offenbar `@eaDir`-Einträge an).
- **Task-IDs müssen JSON-kodiert gesendet werden.** `taskid=<id>` roh findet DSM nur bei einem Teil der Tasks
  (zufällig, ca. 40 %). Die übrigen melden bei `Search list` dauerhaft `finished: true` ohne `total` – das ist die
  Ursache für den oben beschriebenen „Zwischenzustand“ und für „`extension=jpg` nach 180 s ohne total“ – und bei
  `DirSize status` Fehler 599. Mit `taskid="<id>"` (JSON-String) funktionieren alle Tasks sofort. Die Regel
  „fertig erst mit `finished` und `total`“ bleibt als Absicherung im Code.
- **Search-Parameter:** `filetype` kennt nur `file`/`dir`/`all`. Typ-Filter (Audio, Bilder …) laufen über
  `extension` mit kommagetrennter Liste (`mp3,flac,…`), das funktioniert. `folder_path` als JSON-Array mit mehreren
  Ordnern funktioniert. Ohne Treffer kommt `total: 0`. Ein finaler `total` von genau 1000 kam bei einer Suche vor –
  möglicherweise eine Obergrenze; die App zeigt höchstens 500 Treffer und bittet sonst ums Verfeinern.
- **DirSize:** `status` nach `finished: true` liefert 599 (Task ist weg); die App pollt danach nicht weiter.
- **Zertifikat auf Android 11:** Das NAS liefert die Kette vollständig aus (Leaf → „YE2“ → „Root YE“ → ISRG Root X2,
  `openssl s_client` meldet „Verify return code: 0“). Android 11 (Samsung A40) fehlt aber ISRG Root X2 im Trust Store
  (kam erst mit Android 14; auf dem A40 geprüft, auf dem OnePlus vorhanden). Behoben ohne Pinning: Die App bündelt
  die öffentliche ISRG Root X2 (`lib/core/network/trusted_roots.dart`, Fingerprint gegen letsencrypt.org geprüft)
  und fügt sie dem `SecurityContext` **zusätzlich** zu den System-Roots hinzu. Nach Löschen der App-Daten erscheint
  auf dem A40 kein Zertifikat-Dialog mehr.

## Nachtrag M4 (26.09.2026)

Für Screens 08/09/14/20–24 per curl gegen das NAS geprüft. Das Testkonto darf auf dem einzigen sichtbaren Share
(`/Daten`) **nicht schreiben**; schreibende Aktionen ließen sich deshalb nur bis zur Ablehnung prüfen. Auf dem NAS
wurde nichts angelegt, verschoben oder gelöscht.

- **ACL `write: false` ist echt.** `CreateFolder` (im Share und in einem Unterordner) und `Upload` scheitern mit 407
  (`CreateFolder`: `{"code": 1100, "errors": [{"code": 407, "path": …}]}`), obwohl der Share `share_right: "RW"`
  meldet. `NasPerm` wird jetzt aus der ACL abgeleitet; `share_right` kann nur noch einschränken (RO). `del: true`
  steht trotzdem in der ACL – Löschen könnte also gehen, wurde aber nicht an echten Dateien probiert.
- **Fehlercodes stecken bei Datei-Operationen in `error.errors[0].code`** (1100 CreateFolder, 1200 Rename, …). Der
  Client mappt jetzt diesen inneren Code (407 → keine Berechtigung, 408 → nicht gefunden, 414 → existiert schon).
  Bei `SYNO.API.Auth` ist `errors` eine Map (OTP-Typen) und wird ignoriert.
- **CopyMove/Delete-Status:** Fehler einzelner Pfade kommen in einem *erfolgreichen* `status` als
  `{"finished": true, "status": "FAIL", "errors": [{"code": 408, …}], "progress": 1}`; der Client wirft dann. Wie bei
  DirSize liefert `status` nach `finished` 599. `dest_folder_path` als JSON-String wird angenommen. `Delete` auf einen
  fehlenden Pfad meldet einfach `finished: true` ohne Fehler.
- **`getinfo` mit mehreren Pfaden** liefert für fehlende Pfade `{"code": 408, "path": …}` statt eines Fehlers – damit
  sucht der Upload ohne „Überschreiben“ in einem Aufruf den ersten freien Namen `name (1).ext` … `name (9).ext`.
- **Download:** fehlender Pfad → HTTP 502 mit HTML-Seite (kein JSON); ungültige SID → HTTP 200 mit JSON 119 und
  Header `x-request-error: unauth`. Der Download-Stream prüft deshalb den Content-Type.
- **`#recycle`:** `list` auf `/Daten/#recycle` → 407 (Papierkorb nur für Administratoren sichtbar). Screen 24 zeigt
  den Share deshalb nicht; der Lösch-Dialog sagt „nicht prüfbar“.
- **Sharing:** `list` → leer, `create` → 407 (Konto ohne Freigabe-Recht), auch mit `path` als JSON-Array.
  `delete` mit unbekannter ID → 401. `clear_invalid` → success (lief einmal bei 0 Links, ohne Wirkung). Format von
  `date_expired` in `list`-Antworten und die Frage, ob ein Link am Ablauftag noch gilt, sind damit **offen**.
- **Offen, braucht ein Konto mit Schreib-/Freigaberecht:** Upload (Multipart-Feldnamen, `overwrite`-Werte),
  CopyMove/Delete mit echtem Fortschritt, Rename, CreateFolder mit `force_parent`, Wiederherstellen aus `#recycle`,
  Sharing create/list/delete inkl. URL-Host und `date_expired`.
