# Datenschutzerklärung – Synology Explorer

Stand: September 2026 · Gilt für die Android- und iOS-App „Synology Explorer“.

**Kurz:** Die App erhebt keine Daten. Sie spricht ausschließlich mit dem NAS, das du selbst einträgst. Es gibt
keine Analytics, keine Werbung, keine Crash-Reporter mit Upload und keine Server des Entwicklers.

## Welche Daten verarbeitet werden und wo sie liegen

| Daten | Zweck | Ort |
| --- | --- | --- |
| Server-Profile (Name, Adressen, Benutzername) | Verbindung zum NAS | App-Datenbank auf dem Gerät |
| Session-ID, Geräte-Token (2FA), optional Passwort („Passwort merken“, standardmäßig aus) | Anmeldung am NAS | Android Keystore bzw. iOS Keychain |
| Bestätigte Zertifikats-Fingerprints | Schutz vor ausgetauschten Zertifikaten | Android Keystore bzw. iOS Keychain |
| Favoriten, Zuletzt geöffnet, Wiedergabepositionen, Einstellungen | Komfortfunktionen | App-Datenbank auf dem Gerät |
| Vorschaubilder und zwischengespeicherte Medien | schnellere Anzeige | App-eigenes Cache-Verzeichnis, Dateinamen als Hash |
| Offline-Dateien | Nutzung ohne Verbindung | App-eigenes Dokumente-Verzeichnis |
| Deine Dateien, Fotos und Videos | Anzeigen, Hoch- und Herunterladen | nur zwischen Gerät und deinem NAS |

Nichts davon verlässt das Gerät, außer bei Anfragen an dein NAS. Welche Daten das NAS selbst protokolliert (z. B.
Anmeldungen, Dateizugriffe), bestimmt dein DSM, nicht die App.

## Verbindung

- Nur zu den Adressen, die du einträgst (LAN, DDNS/Reverse Proxy, VPN). QuickConnect und andere Relay-Dienste werden
  nicht genutzt.
- HTTPS ist Standard. Selbstsignierte Zertifikate werden erst nach deiner Bestätigung per Fingerprint gepinnt; ändert
  sich das Zertifikat, blockiert die App die Verbindung. HTTP ist möglich, wird aber als unsicher markiert.
- Bei fehlerhafter Anmeldung versucht die App es nicht automatisch erneut (Schutz vor der DSM-Sperre).

## Berechtigungen

| Berechtigung | Wofür | Wann gefragt |
| --- | --- | --- |
| Fotos und Videos (Mediathek) | Auto-Upload neuer Aufnahmen; Lesen der Originale inkl. Aufnahmeort (EXIF) für eine vollständige Sicherung | erst beim Einschalten des Auto-Uploads |
| Fotos hinzufügen | „In Fotos speichern“ | beim ersten Speichern |
| Kamera | Foto aufnehmen und hochladen | beim ersten Aufnehmen |
| Benachrichtigungen | Fortschritt von Transfers, Player-Steuerung | beim ersten Transfer bzw. bei der Wiedergabe |
| Hintergrundausführung | Musik im Hintergrund, Auto-Upload (Android: WorkManager; iOS: vom System geplant) | – |

Standort, Kontakte, Mikrofon oder Werbe-IDs nutzt die App nicht.

## Löschen

- Einstellungen › „Alle lokalen Daten löschen“ entfernt Cache, Offline-Dateien, Transfers, Session-IDs,
  Geräte-Tokens, gemerkte Passwörter und bestätigte Zertifikate.
- Ein Server-Profil zu löschen entfernt dessen Favoriten, Verlauf und Anmeldedaten.
- Deinstallieren der App entfernt alle App-Daten vom Gerät.
- Auf dem NAS gespeicherte Dateien (z. B. per Auto-Upload) bleiben dort, bis du sie löschst.

## Freigabelinks

Freigabelinks erzeugt dein NAS. Die App schlägt ein Ablaufdatum vor und kopiert Links nur nach deiner Bestätigung in
die Zwischenablage.

## Kontakt

Fragen und Hinweise bitte als Issue auf [github.com/jw29435/synology-explorer](https://github.com/jw29435/synology-explorer/issues).

---

# Privacy policy (English summary)

The app collects no data. It only talks to the NAS you configure. There is no analytics, advertising, crash upload
or developer server. Sessions, device tokens, optional passwords and certificate pins are stored in the Android
Keystore / iOS Keychain; everything else (profiles, favorites, playback positions, cache, offline files) stays in the
app's private storage on your device. Photo library access is requested only when you turn on auto upload and is used
solely to copy new photos/videos to your NAS. “Delete all local data” in the settings removes cache, offline files,
transfers, tokens, saved passwords and trusted certificates.
