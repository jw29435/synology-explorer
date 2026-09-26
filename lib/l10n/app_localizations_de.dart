// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Synology Explorer';

  @override
  String get tabFiles => 'Dateien';

  @override
  String get tabOffline => 'Offline';

  @override
  String get tabTransfers => 'Transfers';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get done => 'Fertig';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get more => 'Mehr';

  @override
  String get serversTitle => 'Server';

  @override
  String get serverAdd => 'Server hinzufügen';

  @override
  String get serverEditTitle => 'Server bearbeiten';

  @override
  String get serversEmpty => 'Noch kein Server eingerichtet.';

  @override
  String serverConnectedVia(String via) {
    return 'Verbunden über $via';
  }

  @override
  String get viaLan => 'LAN';

  @override
  String get viaExternal => 'extern';

  @override
  String get serverNotConnected => 'Nicht verbunden';

  @override
  String get serverInfo =>
      'Beim Start wird zuerst die LAN-Adresse probiert, dann die externe. QuickConnect wird nicht unterstützt.';

  @override
  String get serverEdit => 'Bearbeiten';

  @override
  String get serverLogout => 'Abmelden';

  @override
  String get serverDelete => 'Löschen';

  @override
  String serverDeleteConfirm(String name) {
    return '„$name“ löschen? Favoriten und Verlauf dieses Servers werden entfernt.';
  }

  @override
  String get fieldName => 'Name';

  @override
  String get fieldLanUrl => 'LAN-Adresse';

  @override
  String get fieldLanUrlHint => 'Wird zuerst probiert, Timeout 2 s.';

  @override
  String get fieldExternalUrl => 'Externe Adresse (optional)';

  @override
  String get fieldExternalUrlHint =>
      'DDNS, Reverse Proxy oder Tailscale-Adresse.';

  @override
  String get fieldUser => 'Benutzer';

  @override
  String get fieldPassword => 'Passwort';

  @override
  String get rememberPassword => 'Passwort auf dem Gerät merken';

  @override
  String get rememberPasswordHint =>
      'Sonst nur Session-Token; Re-Login fragt neu.';

  @override
  String get httpsInfo =>
      'Nur HTTPS. Selbstsignierte Zertifikate werden beim ersten Verbinden per Fingerprint bestätigt.';

  @override
  String get httpWarning =>
      'Unverschlüsselt (HTTP): Passwort und Dateien sind im Netz lesbar.';

  @override
  String get connect => 'Verbinden';

  @override
  String get validationRequired => 'Pflichtfeld';

  @override
  String get validationUrl =>
      'Keine gültige Adresse, z. B. https://192.168.178.20:5001';

  @override
  String get certTitle => 'Unbekanntes Zertifikat';

  @override
  String certIntro(String host) {
    return 'Der Server $host verwendet ein Zertifikat, dem dieses Gerät nicht vertraut (selbstsigniert oder unbekannte Zertifizierungsstelle). Vergleiche den Fingerprint mit DSM (Systemsteuerung › Sicherheit › Zertifikat), bevor du vertraust.';
  }

  @override
  String get certSubject => 'Ausgestellt für';

  @override
  String get certIssuer => 'Aussteller';

  @override
  String get certValidity => 'Gültig';

  @override
  String get certFingerprint => 'SHA-256-Fingerprint';

  @override
  String get certPinInfo =>
      'Beim Vertrauen wird der Fingerprint gepinnt. Ändert er sich, blockiert die App die Verbindung.';

  @override
  String get certTrust => 'Vertrauen';

  @override
  String get otpTitle => 'Bestätigungscode';

  @override
  String get otpHeading => 'Zwei-Faktor-Authentifizierung';

  @override
  String otpIntro(String account) {
    return 'Gib den 6-stelligen Code aus deiner Authenticator-App für $account ein.';
  }

  @override
  String get otpCode => 'Code';

  @override
  String get otpRemember => 'Dieses Gerät merken';

  @override
  String get otpRememberHint =>
      'Fordert ein Geräte-Token an, kein Code beim nächsten Login.';

  @override
  String get errorUnauthorized => 'Benutzer oder Passwort falsch.';

  @override
  String get errorAccountLocked =>
      'Konto gesperrt oder IP durch Auto-Block blockiert. Kein automatischer Neuversuch.';

  @override
  String get errorOtpRequired => 'Bestätigungscode erforderlich.';

  @override
  String get errorOtpInvalid =>
      'Code ungültig oder abgelaufen. Kein automatischer Neuversuch (Auto-Block).';

  @override
  String get errorSessionExpired => 'Sitzung abgelaufen. Bitte neu anmelden.';

  @override
  String get errorPermission => 'Keine Berechtigung.';

  @override
  String get errorNotFound => 'Nicht gefunden.';

  @override
  String get errorNetwork => 'Server nicht erreichbar.';

  @override
  String errorHttp(int status) {
    return 'Server antwortet mit HTTP $status.';
  }

  @override
  String errorCertMismatch(String host) {
    return 'Das Zertifikat von $host hat sich geändert. Verbindung blockiert.';
  }

  @override
  String errorCode(int code) {
    return 'Fehler $code vom NAS.';
  }

  @override
  String get errorGeneric => 'Unerwarteter Fehler.';

  @override
  String get sectionShares => 'Freigegebene Ordner';

  @override
  String get sectionFavorites => 'Favoriten';

  @override
  String get sectionRecent => 'Zuletzt geöffnet';

  @override
  String get permReadWrite => 'Lesen/Schreiben';

  @override
  String get permReadOnly => 'Nur Lesen';

  @override
  String serverStatus(String via, String user) {
    return '$via · $user';
  }

  @override
  String get search => 'Suchen';

  @override
  String get switchServer => 'Server wechseln';

  @override
  String today(String time) {
    return 'heute $time';
  }

  @override
  String get yesterday => 'gestern';

  @override
  String get datePattern => 'dd.MM.yyyy';

  @override
  String get sortName => 'Name';

  @override
  String get sortDate => 'Datum';

  @override
  String get sortSize => 'Größe';

  @override
  String get sortType => 'Typ';

  @override
  String get sortAscending => 'Aufsteigend';

  @override
  String get sortDescending => 'Absteigend';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String get folderEmpty => 'Dieser Ordner ist leer.';

  @override
  String get viewGrid => 'Rasteransicht';

  @override
  String get viewList => 'Listenansicht';

  @override
  String get openLater =>
      'Dateien öffnen kommt mit M2 (Audio) und M3 (Viewer).';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get actionPlayFromHere => 'Abspielen ab hier';

  @override
  String get actionPlayFolder => 'Ordner abspielen (inkl. Unterordner)';

  @override
  String get actionQueue => 'Zur Queue hinzufügen';

  @override
  String get actionDownload => 'Herunterladen';

  @override
  String get actionOffline => 'Offline verfügbar halten';

  @override
  String get actionFavoriteAdd => 'Zu Favoriten';

  @override
  String get actionFavoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get actionShareLink => 'Freigabelink erstellen';

  @override
  String get actionRename => 'Umbenennen';

  @override
  String get actionMove => 'Verschieben nach …';

  @override
  String get actionCopy => 'Kopieren nach …';

  @override
  String get actionInfo => 'Info';

  @override
  String get actionDelete => 'Löschen (in Papierkorb)';

  @override
  String availableFrom(String milestone) {
    return 'ab $milestone';
  }

  @override
  String get infoPath => 'Pfad';

  @override
  String get infoSize => 'Größe';

  @override
  String infoSizeBytes(String size, String bytes) {
    return '$size ($bytes Bytes)';
  }

  @override
  String get infoCreated => 'Erstellt';

  @override
  String get infoModified => 'Geändert';

  @override
  String get infoOwner => 'Besitzer';

  @override
  String get infoPerm => 'Rechte';

  @override
  String get infoFolder => 'Ordner';

  @override
  String get computeSize => 'Größe berechnen';

  @override
  String dirSizeResult(String size, String files, String dirs) {
    return '$size · $files Dateien · $dirs Ordner';
  }

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String get pathCopied => 'Pfad kopiert';

  @override
  String get searchHint => 'Dateiname';

  @override
  String searchIn(String folder) {
    return 'Suche in $folder (rekursiv)';
  }

  @override
  String get searchWholeNas => 'Ganzes NAS';

  @override
  String get searchAllShares => 'Suche in allen freigegebenen Ordnern';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterAudio => 'Audio';

  @override
  String get filterImage => 'Bilder';

  @override
  String get filterVideo => 'Video';

  @override
  String get filterDocument => 'Dokumente';

  @override
  String searchRunning(int count) {
    return 'Suche läuft … $count Treffer bisher';
  }

  @override
  String searchDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
      zero: 'Keine Treffer',
    );
    return '$_temp0';
  }

  @override
  String searchTruncated(int shown, int total) {
    return 'Die ersten $shown von $total Treffern – Suche verfeinern.';
  }

  @override
  String get searchFooter =>
      'Suche nach Dateiname. Filter schränken auf Dateiendungen ein; beim Verlassen wird der Search-Task gestoppt und aufgeräumt.';

  @override
  String get selectAll => 'Alle';

  @override
  String selectionSize(String size) {
    return 'Auswahl: $size';
  }

  @override
  String get actionDownloadShort => 'Download';

  @override
  String get actionMoveShort => 'Verschieben';

  @override
  String get actionCopyShort => 'Kopieren';

  @override
  String get actionShareShort => 'Teilen';

  @override
  String get back => 'Zurück';

  @override
  String get create => 'Anlegen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get copy => 'Kopieren';

  @override
  String get share => 'Teilen';

  @override
  String get pause => 'Pausieren';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get validationName => 'Ungültiger Name (kein „/“).';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get newFolderHint => 'Im aktuellen Verzeichnis';

  @override
  String get moveTo => 'Verschieben nach …';

  @override
  String get copyTo => 'Kopieren nach …';

  @override
  String get moveHere => 'Hierher verschieben';

  @override
  String get copyHere => 'Hierher kopieren';

  @override
  String get noSubfolders => 'Keine Unterordner.';

  @override
  String moving(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verschiebe $count Elemente …',
      one: 'Verschiebe 1 Element …',
    );
    return '$_temp0';
  }

  @override
  String copying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kopiere $count Elemente …',
      one: 'Kopiere 1 Element …',
    );
    return '$_temp0';
  }

  @override
  String deleting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lösche $count Elemente …',
      one: 'Lösche 1 Element …',
    );
    return '$_temp0';
  }

  @override
  String deleteConfirmOne(String name) {
    return '„$name“ löschen?';
  }

  @override
  String deleteConfirmMany(int count) {
    return '$count Elemente löschen?';
  }

  @override
  String get deleteToRecycle =>
      'Die Freigabe hat einen Papierkorb: Gelöschtes lässt sich dort wiederherstellen.';

  @override
  String get deleteNoRecycle =>
      'Die Freigabe hat keinen Papierkorb: Löschen ist endgültig.';

  @override
  String get deleteRecycleUnknown =>
      'Ob die Freigabe einen Papierkorb hat, ist nicht prüfbar (evtl. nur für Administratoren sichtbar). Im Zweifel ist Löschen endgültig.';

  @override
  String downloadsQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Downloads eingereiht.',
      one: '1 Download eingereiht.',
      zero: 'Nichts herunterzuladen.',
    );
    return '$_temp0';
  }

  @override
  String uploadsQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Uploads eingereiht.',
      one: '1 Upload eingereiht.',
    );
    return '$_temp0';
  }

  @override
  String get uploadTitle => 'Hinzufügen';

  @override
  String uploadTarget(String path) {
    return 'Ziel: $path';
  }

  @override
  String get uploadFiles => 'Dateien';

  @override
  String get uploadFilesHint => 'Aus dem System-Dateipicker';

  @override
  String get uploadMedia => 'Fotos & Videos';

  @override
  String get uploadMediaHint => 'Aus der Kamera-Rolle';

  @override
  String get uploadCamera => 'Kamera';

  @override
  String get uploadCameraHint => 'Aufnehmen und direkt hochladen';

  @override
  String get uploadOverwrite => 'Vorhandene Dateien überschreiben';

  @override
  String get uploadOverwriteHint => 'Sonst wird „ (1)“ angehängt';

  @override
  String get pauseAll => 'Alle pausieren';

  @override
  String get clearList => 'Liste leeren';

  @override
  String transfersActive(int count) {
    return 'Aktiv ($count)';
  }

  @override
  String transfersDone(int count) {
    return 'Fertig ($count)';
  }

  @override
  String get transfersNone => 'Keine laufenden Transfers.';

  @override
  String get transfersNoneDone => 'Noch nichts fertig.';

  @override
  String get transfersFooter =>
      'Die Queue überlebt einen App-Neustart. Downloads werden per HTTP-Range fortgesetzt, Uploads starten auf Datei-Ebene neu.';

  @override
  String get transferToOffline => 'Download → Offline';

  @override
  String transferToFolder(String folder) {
    return 'Upload → $folder';
  }

  @override
  String get transferQueued => 'wartet';

  @override
  String get transferPaused => 'Pausiert';

  @override
  String transferFailed(String reason) {
    return 'Fehlgeschlagen: $reason';
  }

  @override
  String bytesOf(String done, String total) {
    return '$done von $total';
  }

  @override
  String remaining(String time) {
    return 'noch $time';
  }

  @override
  String durationSeconds(int n) {
    return '$n s';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String durationHours(int n) {
    return '$n h';
  }

  @override
  String get resumesWithRange => 'wird fortgesetzt (Range)';

  @override
  String notificationTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Transfers laufen',
      one: '1 Transfer läuft',
    );
    return '$_temp0';
  }

  @override
  String get errorExists => 'Ein Element mit diesem Namen gibt es dort schon.';

  @override
  String get errorLocalFile => 'Lokale Datei nicht lesbar oder schreibbar.';

  @override
  String get storageUsed => 'Belegt auf diesem Gerät';

  @override
  String storageOffline(String size) {
    return 'Offline-Dateien $size';
  }

  @override
  String storageCache(String size) {
    return 'Cache $size';
  }

  @override
  String get offlineInfo =>
      'Alles hier ist ohne Verbindung nutzbar. Änderungen auf dem NAS werden beim nächsten Kontakt geprüft (mtime).';

  @override
  String get offlineEmpty =>
      'Noch keine Offline-Dateien. „Offline verfügbar halten“ im Datei-Menü lädt Dateien hierher.';

  @override
  String get offlineChanged => 'Auf dem NAS geändert – aktualisieren?';

  @override
  String get offlineRemove => 'Entfernen';

  @override
  String moreItems(int count) {
    return '+ $count weitere';
  }

  @override
  String get openFailed => 'Keine App zum Öffnen gefunden.';

  @override
  String get shareLinkTitle => 'Freigabelink';

  @override
  String get shareValidUntil => 'Gültig bis';

  @override
  String get expiryDay1 => '1 Tag';

  @override
  String expiryDays(int count) {
    return '$count Tage';
  }

  @override
  String get expiryNever => 'Nie';

  @override
  String get expiryNone => 'Kein Ablauf';

  @override
  String expiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String get expiresToday => 'Läuft heute ab';

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Läuft ab in $count Tagen',
      one: 'Läuft morgen ab',
    );
    return '$_temp0';
  }

  @override
  String expiredOn(String date) {
    return 'Abgelaufen am $date';
  }

  @override
  String get sharePassword => 'Passwort (optional)';

  @override
  String get generate => 'Generieren';

  @override
  String get shareCreate => 'Link erstellen';

  @override
  String get shareCreated => 'Link erstellt';

  @override
  String get linkCopied => 'Link kopiert.';

  @override
  String get shareExternalHint =>
      'Der Link zeigt auf die externe Adresse. Verwaltung aller Links unter Einstellungen › Freigabelinks.';

  @override
  String get shareNoExternal =>
      'Für diesen Server ist keine externe Adresse hinterlegt: Der Link nutzt die Adresse, die DSM meldet, und ist evtl. nur im LAN erreichbar.';

  @override
  String get shareLinksTitle => 'Freigabelinks';

  @override
  String shareLinksCount(int active, int expired) {
    return '$active aktiv · $expired abgelaufen';
  }

  @override
  String get shareLinksEmpty => 'Keine Freigabelinks.';

  @override
  String get shareLinksFooter =>
      'Quelle: SYNO.FileStation.Sharing list. Ablauf oder Passwort ändern geht über Link neu erstellen.';

  @override
  String get passwordBadge => 'Passwort';

  @override
  String get cleanUp => 'Aufräumen';

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get trashEmptyAction => 'Leeren';

  @override
  String get trashChecking => 'Prüfe Papierkörbe …';

  @override
  String get trashInfo => 'Zeigt #recycle der Freigabe.';

  @override
  String get trashNone => 'Kein Papierkorb sichtbar.';

  @override
  String trashHidden(String shares) {
    return 'Fehlt: $shares – dort ist der Papierkorb nur für Admins sichtbar.';
  }

  @override
  String get trashIsEmpty => 'Der Papierkorb ist leer.';

  @override
  String get trashFooter =>
      'Wiederherstellen = Verschieben zurück an den Ursprungspfad (aus dem Papierkorb-Pfad abgeleitet). Endgültiges Löschen braucht eine zweite, rote Bestätigung.';

  @override
  String trashFrom(String folder) {
    return 'aus $folder';
  }

  @override
  String trashDeleted(String when) {
    return 'gelöscht $when';
  }

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get restoring => 'Stelle wieder her …';

  @override
  String restored(String path) {
    return 'Wiederhergestellt nach $path';
  }

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String get deleteForeverTitle => 'Endgültig löschen?';

  @override
  String deleteForeverOne(String name) {
    return '„$name“ wird aus dem Papierkorb entfernt. Das kann nur noch ein Snapshot rückgängig machen.';
  }

  @override
  String deleteForeverMany(int count) {
    return '$count Elemente werden aus dem Papierkorb entfernt. Das kann nur noch ein Snapshot rückgängig machen.';
  }

  @override
  String get actionDeleteShort => 'Löschen';
}
