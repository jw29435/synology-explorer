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
- Gerät: zwei Android-Handys per USB – ein älteres Samsung Galaxy A40 (`R58MC1T7R4D`, Android 11/API 30; Referenz für
  Min-API und schwache Hardware) und ein aktuelles OnePlus 9 Pro (`4c5ce6f6`, Android 16/API 36; Hauptgerät). Geräte immer
  explizit mit `-s <id>` ansprechen, nie das erste in der Liste. Neue Features zuerst auf dem OnePlus, vor dem PR einmal
  auf dem Samsung gegenprüfen.
- adb-Setup: Die Geräte hängen per USB am Windows-Host, der adb-Server läuft dort. WSL läuft im NAT-Modus und erreicht
  diesen Server nicht. Deshalb adb immer über das Windows-Binary `adb.exe` (im PATH) aufrufen, nie das Linux-`adb` –
  das startet einen eigenen Server ohne Geräte. `flutter run`/`flutter devices` sehen die Handys daher nicht; stattdessen:
  ```sh
  flutter build apk --debug
  adb.exe -s <id> install -r "$(wslpath -w build/app/outputs/flutter-apk/app-debug.apk)"
  adb.exe -s <id> shell am start -n de.jw29435.synology_explorer/.MainActivity
  adb.exe -s <id> logcat -s flutter           # Logs
  adb.exe -s <id> exec-out screencap -p > screen.png
  ```
  Kein Hot Reload. Nie `adb.exe -a` oder `adb.exe tcpip` (öffnet adb ins Netz), keine usbipd/udev-Umbauten.
  Zeigt `adb.exe devices` ein Gerät nicht: den Nutzer bitten, USB-Verbindung und Debugging-Freigabe am Handy zu prüfen.

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
