# autoupload

Neue Fotos/Videos aus der Kamera-Rolle in einen Zielordner auf dem NAS (Schema `JJJJ/MM`, optional nur WLAN/Laden).
Screen 25.

- `domain/` – Einstellungen (JSON in der drift-Tabelle `settings`), Cursor und Delta-Erkennung
- `data/` – `CameraRoll` (photo_manager), `AutoUploader` (ein Lauf über die TransferQueue), Protokoll in
  `auto_upload_runs`, Hintergrund-Task (`background.dart`, workmanager auf Android und iOS)
- Gesichert wird, was nach dem Einschalten aufgenommen wird; Android nur aus `DCIM/`.
