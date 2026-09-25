# Synology Explorer

Flutter-Client für Android und iOS, der Dateien auf einem Synology NAS über die File-Station-API browst, verwaltet
und direkt wiedergibt – mit Musik als Kernfunktion. Der Player läuft im Hintergrund, ist über Sperrbildschirm und
Kopfhörer steuerbar, merkt sich die Position und behandelt jeden Ordner als Wiedergabeliste. PDF, Bilder, Video und
Text werden in Viewern angezeigt. Funktionales Vorbild ist DS File; Optik und Bedienung sind eigenständig.

Kein eigener Server, keine Cloud, keine Telemetrie – die App spricht ausschließlich mit der DSM Web API deines NAS.

**Status:** in Entwicklung – noch nicht nutzbar. Konzept, Architektur und Roadmap: [docs/CONCEPT.md](docs/CONCEPT.md).

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

## Lizenz

[CC0 1.0 Universal](LICENSE). Mitgelieferte Schriften (Manrope, JetBrains Mono) stehen unter der SIL Open Font
License, siehe `assets/fonts/`.
