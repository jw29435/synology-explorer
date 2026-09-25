# CLAUDE.md – Synology Explorer

Flutter-Client für Synology NAS (File-Station-API), Fokus Audio-Wiedergabe. Android + iOS.
Konzept: `docs/CONCEPT.md` (Architektur, API-Mapping, Screen-Katalog, Roadmap). Mockups: `docs/mockups/*.png`
(Nummern 01–26 entsprechen dem Screen-Katalog in CONCEPT.md, Abschnitt 7).

## Vor jeder Aufgabe
1. `docs/CONCEPT.md` lesen, mindestens Abschnitte 4 (API), 5 (Architektur) und 7 (Screens).
2. Den Mockup-PNG des Screens ansehen, bevor du UI baust. Optik und Bedienung folgen den Mockups, nicht DS File.
3. Bestehende Struktur unter `lib/` respektieren; keine parallelen Strukturen anlegen.

## Stack (festgelegt, nicht ohne Rückfrage ändern)
- Flutter stable, Dart 3, Null-Safety. Min. Android API 26, iOS 15.
- State/DI: `riverpod` + `riverpod_generator`. Navigation: `go_router`. HTTP: `dio`.
- Modelle: `freezed` + `json_serializable`. Lokale DB: `drift`. Secrets: `flutter_secure_storage`.
- Audio: `just_audio` + `audio_service`. Video: `media_kit`. Bilder: `photo_view`. PDF: `pdfrx`. Markdown: `flutter_markdown`.
- Lokalisierung: `flutter_localizations` + ARB (`lib/l10n/app_de.arb`, `app_en.arb`). Keine hartkodierten UI-Strings.
- Neue Pakete nur, wenn CONCEPT.md sie nennt oder du den Grund im PR beschreibst.

## Architektur
- Feature-first: `lib/features/<feature>/{data,domain,presentation}`, Geteiltes in `lib/core/`.
- Widgets rufen nie direkt die API; nur über Riverpod-Provider → Repository → API-Wrapper.
- Alle Synology-Aufrufe gehen durch `core/network/syno_api_client.dart` (SID-Interceptor, Re-Login-Policy, Fehler-Mapping auf `SynoException`).
- API-Versionen kommen aus `SYNO.API.Info`, nie hartkodiert.

## Sicherheitsregeln (hart)
- Niemals TLS-Verifikation global abschalten. Selbstsignierte Zertifikate nur per Fingerprint-Pinning nach Nutzerbestätigung.
- Passwörter nie loggen, nie in SharedPreferences. SID/Geräte-Token nur im Secure Storage.
- Kein automatischer Login-Retry bei Auth-Fehlern (DSM Auto-Block). Re-Login nur bei abgelaufener Session, maximal einmal je Request-Kette.
- Keine Analytics, keine Drittserver, kein Telemetrie-Paket.
- Keystores, `.env`, API-Keys niemals committen.

## Tests und Definition of Done
- `flutter analyze` ohne Warnungen, `dart format --set-exit-if-changed .` sauber, `flutter test` grün.
- Neue Logik (Parser, Fehler-Mapping, Queue, Auto-Upload-Delta) bekommt Unit-Tests.
- Neue Screens bekommen mindestens einen Widget-Test (rendert, Hauptaktion auslösbar).
- Netzwerk-Tests laufen gegen den Mock-Server in `tool/mock_nas/` mit Fixtures aus `test/fixtures/`, nie gegen ein echtes NAS.
- Kein echtes NAS in CI. Das echte NAS wird nur in ausdrücklich dafür vorgesehenen Schritten (Spike, Gerätetest) angesprochen,
  Zugangsdaten kommen dann aus Umgebungsvariablen (NAS_URL, NAS_USER, NAS_PASS, NAS_OTP) und landen nie in Dateien oder Logs.
- Gerät: zwei Android-Handys per USB – ein älteres Samsung (Referenz für Min-API und schwache Hardware) und ein aktuelles
  OnePlus (Hauptgerät). Geräte immer explizit mit `flutter run -d <id>` / `adb -s <id>` ansprechen, nie das erste in der Liste.
  Neue Features zuerst auf dem OnePlus, vor dem PR einmal auf dem Samsung gegenprüfen.
- adb-Setup: Der adb-Server läuft unter Windows, die Geräte hängen dort per USB. Der Linux-adb-Client in WSL ist über
  `ADB_SERVER_SOCKET=tcp:127.0.0.1:5037` mit ihm verbunden. Deshalb NIE `adb kill-server`, `adb start-server`, `adb -a`,
  `adb tcpip` oder usbipd/udev ausführen. Zeigt `adb devices` nichts: den Nutzer bitten, unter Windows `adb devices` zu prüfen,
  nicht selbst am Server drehen. `flutter run` nur, wenn `adb devices` das Zielgerät zeigt; sonst nur `build`/`test`.

## Arbeitsweise
- Ein Prompt = ein Branch = ein PR. Branch-Name `feat/<milestone>-<thema>`, z. B. `feat/m1-browser`.
- Conventional Commits (`feat:`, `fix:`, `test:`, `chore:`, `docs:`).
- Kleine, nachvollziehbare Commits. Nicht angefragte Refactorings unterlassen.
- Bei Unklarheit in CONCEPT.md: Annahme im PR-Text dokumentieren, nicht still entscheiden.
- Am Ende jeder Aufgabe: kurze Zusammenfassung mit offenen Punkten und was auf einem echten Gerät/NAS geprüft werden muss.

## UI-Sprache und Design
- UI-Texte auf Deutsch (Default) und Englisch, über ARB.
- Design-Tokens aus den Mockups: Hintergrund `#15171C`, Fläche `#1F2229`, erhöhte Fläche `#23272F`, Rahmen `#2B303A`,
  Text `#EDEFF3`, Sekundärtext `#A3A9B5`, gedämpft `#7C8494`, Akzent `#F2A93B`, Erfolg `#4CC38A`, Info `#5AB0FF`, Fehler `#F0A8A8`/`#D64545`.
  Schrift Manrope (UI), JetBrains Mono (Pfade/Zeiten). Touch-Ziele mindestens 44 px. Theme in `lib/app/theme.dart` zentral, nicht inline.
