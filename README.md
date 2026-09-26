# Synology Explorer

Flutter-Client für Android und iOS, der Dateien auf einem Synology NAS über die File-Station-API browst, verwaltet
und direkt wiedergibt – mit Musik als Kernfunktion. Der Player läuft im Hintergrund, ist über Sperrbildschirm und
Kopfhörer steuerbar, merkt sich die Position und behandelt jeden Ordner als Wiedergabeliste. PDF, Bilder, Video und
Text werden in Viewern angezeigt. Funktionales Vorbild ist DS File; Optik und Bedienung sind eigenständig.

Kein eigener Server, keine Cloud, keine Telemetrie – die App spricht ausschließlich mit der DSM Web API deines NAS.

**Status:** v1.0 – alle Screens aus dem Konzept umgesetzt (Browsen, Audio, Viewer, Verwaltung, Transfers, Offline,
Freigabelinks, Papierkorb, Auto-Upload, Einstellungen). Konzept, Architektur und Roadmap:
[docs/CONCEPT.md](docs/CONCEPT.md). Datenschutz: [PRIVACY.md](PRIVACY.md).

## Screenshots

<!-- Platzhalter: Screenshots aus der App (1080 × 2340) unter docs/screenshots/ ablegen und hier einbinden. -->

| Dateien | Now Playing | Auto-Upload | Einstellungen |
| --- | --- | --- | --- |
| _folgt_ | _folgt_ | _folgt_ | _folgt_ |

Bis dahin zeigen die Entwürfe in [docs/mockups/](docs/mockups/) das Aussehen.

## Installation

| Weg | Für wen | Wie |
| --- | --- | --- |
| GitHub Releases | Android, sofort | Unter [Releases](https://github.com/jw29435/synology-explorer/releases) die passende APK laden – meist `app-arm64-v8a-release.apk` (ältere Geräte: `armeabi-v7a`) – und installieren („Unbekannte Apps installieren“ für den Browser erlauben). |
| Google Play (interner Test) | Android, mit Updates | Einladung an die Tester-Liste; der Link kommt per Mail. |
| TestFlight | iPhone | Einladung per Mail bzw. öffentlicher TestFlight-Link, dann in der TestFlight-App installieren. |

## NAS einrichten

Die App braucht keinen Admin und keinen Home-Dienst. Für ein eigenes Konto (empfohlen):

1. **Benutzer anlegen:** DSM › Systemsteuerung › Benutzer und Gruppe › Erstellen.
2. **File Station zuweisen:** im Benutzer unter *Anwendungen* „File Station“ auf *Zulassen* setzen. Ohne diese
   Berechtigung scheitert die Anmeldung.
3. **Freigegebene Ordner:** unter *Berechtigungen* Lesen/Schreiben für die gewünschten Ordner vergeben. Nur Lesen
   genügt zum Hören und Ansehen; Hochladen, Auto-Upload, Umbenennen und Löschen brauchen Schreibrechte (die App
   sperrt diese Aktionen sonst und sagt warum).
4. **2FA und vertrauenswürdige Geräte:** Ist 2-Faktor-Anmeldung aktiv, unter Systemsteuerung › Sicherheit ›
   Konto „Vertrauenswürdige Geräte zulassen“ (bzw. „Allow trusted devices“) einschalten. Dann fragt die App den Code
   nur bei der ersten Anmeldung („Dieses Gerät merken“).
5. **Erreichbarkeit:** im LAN `https://<ip>:5001`; unterwegs DDNS/Reverse Proxy mit gültigem Zertifikat oder VPN.
   QuickConnect wird nicht unterstützt.
6. **Auto-Block** kann aktiv bleiben: Die App wiederholt fehlgeschlagene Anmeldungen nie automatisch.

Für den Auto-Upload im Hintergrund braucht die App eine gültige Anmeldung. Läuft die Session ab, hilft „Passwort
merken“ beim Server; sonst holt die App die Uploads nach der nächsten Anmeldung nach.

## Unterstützte DSM-Versionen

DSM 7.1 oder neuer. DSM 6 wird nicht getestet. Der Benutzer braucht Zugriff auf File Station und Leserechte auf die
gewünschten freigegebenen Ordner.

## Bauen

Voraussetzungen: Flutter stable, Android SDK (min. API 26) bzw. Xcode (iOS 15+).

```sh
flutter pub get
flutter test
flutter run -d <device-id>        # Gerät explizit wählen, siehe `flutter devices`
flutter build apk --debug
```

Mock-NAS für lokale Tests (liefert Antworten aus `test/fixtures/<api>/<method>.json`):

```sh
dart run tool/mock_nas/main.dart --port 5000
curl "http://127.0.0.1:5000/webapi/entry.cgi?api=SYNO.API.Info&version=1&method=query"
```

## Release

Tags `v*` bauen signierte Artefakte (`.github/workflows/release-android.yml`, `release-ios.yml`). Normalerweise
entstehen Tags über [release-please](https://github.com/googleapis/release-please): Conventional Commits auf `main`
ergeben einen Release-PR mit `CHANGELOG.md` und neuer Version; sein Merge legt Tag und GitHub-Release an und startet
beide Release-Workflows. Die erste Version bekommt 1.0.0 über `Release-As: 1.0.0` im Commit-Text.

Benötigte Repository-Secrets (Settings › Secrets and variables › Actions):

| Secret | Inhalt |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Upload-Keystore, `base64 -w0 upload-keystore.jks` |
| `KEY_PROPERTIES` | Zeilen `storePassword=…`, `keyPassword=…`, `keyAlias=…` (`storeFile` setzt der Workflow) |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON-Schlüssel eines Dienstkontos mit Release-Rechten in der Play Console (optional; ohne nur GitHub-Release) |
| `MATCH_GIT_URL` | Git-URL des privaten fastlane-match-Repos mit Zertifikaten und Profilen |
| `MATCH_PASSWORD` | Passphrase, mit der match das Repo verschlüsselt |
| `APP_STORE_CONNECT_API_KEY` | JSON `{"key_id": "…", "issuer_id": "…", "key": "-----BEGIN PRIVATE KEY-----\n…"}` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | optional: `base64("user:token")`, falls das match-Repo per HTTPS geklont wird |

Optional die Repository-Variable `PLAY_RELEASE_STATUS=draft`, solange die App in der Play Console noch ein Entwurf
ist. Fehlen Secrets, brechen die Workflows mit einem Hinweis ab. Lokal signiert `flutter build apk --release` ohne
`android/key.properties` mit dem Debug-Key.

## Lizenz

[CC0 1.0 Universal](LICENSE). Mitgelieferte Schriften (Manrope, JetBrains Mono) stehen unter der SIL Open Font
License, siehe `assets/fonts/`. Lizenzen der verwendeten Pakete und Bibliotheken (u. a. libmpv/FFmpeg unter LGPL):
[THIRD_PARTY.md](THIRD_PARTY.md), neu erzeugen mit `dart run tool/third_party.dart`.
