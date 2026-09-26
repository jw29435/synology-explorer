import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Synology Explorer'**
  String get appTitle;

  /// No description provided for @tabFiles.
  ///
  /// In de, this message translates to:
  /// **'Dateien'**
  String get tabFiles;

  /// No description provided for @tabOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline'**
  String get tabOffline;

  /// No description provided for @tabTransfers.
  ///
  /// In de, this message translates to:
  /// **'Transfers'**
  String get tabTransfers;

  /// No description provided for @tabSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get tabSettings;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @more.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get more;

  /// No description provided for @serversTitle.
  ///
  /// In de, this message translates to:
  /// **'Server'**
  String get serversTitle;

  /// No description provided for @serverAdd.
  ///
  /// In de, this message translates to:
  /// **'Server hinzufügen'**
  String get serverAdd;

  /// No description provided for @serverEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Server bearbeiten'**
  String get serverEditTitle;

  /// No description provided for @serversEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Server eingerichtet.'**
  String get serversEmpty;

  /// No description provided for @serverConnectedVia.
  ///
  /// In de, this message translates to:
  /// **'Verbunden über {via}'**
  String serverConnectedVia(String via);

  /// No description provided for @viaLan.
  ///
  /// In de, this message translates to:
  /// **'LAN'**
  String get viaLan;

  /// No description provided for @viaExternal.
  ///
  /// In de, this message translates to:
  /// **'extern'**
  String get viaExternal;

  /// No description provided for @serverNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Nicht verbunden'**
  String get serverNotConnected;

  /// No description provided for @serverInfo.
  ///
  /// In de, this message translates to:
  /// **'Beim Start wird zuerst die LAN-Adresse probiert, dann die externe. QuickConnect wird nicht unterstützt.'**
  String get serverInfo;

  /// No description provided for @serverEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get serverEdit;

  /// No description provided for @serverLogout.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get serverLogout;

  /// No description provided for @serverDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get serverDelete;

  /// No description provided for @serverDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ löschen? Favoriten und Verlauf dieses Servers werden entfernt.'**
  String serverDeleteConfirm(String name);

  /// No description provided for @fieldName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldLanUrl.
  ///
  /// In de, this message translates to:
  /// **'LAN-Adresse'**
  String get fieldLanUrl;

  /// No description provided for @fieldLanUrlHint.
  ///
  /// In de, this message translates to:
  /// **'Wird zuerst probiert, Timeout 2 s.'**
  String get fieldLanUrlHint;

  /// No description provided for @fieldExternalUrl.
  ///
  /// In de, this message translates to:
  /// **'Externe Adresse (optional)'**
  String get fieldExternalUrl;

  /// No description provided for @fieldExternalUrlHint.
  ///
  /// In de, this message translates to:
  /// **'DDNS, Reverse Proxy oder Tailscale-Adresse.'**
  String get fieldExternalUrlHint;

  /// No description provided for @fieldUser.
  ///
  /// In de, this message translates to:
  /// **'Benutzer'**
  String get fieldUser;

  /// No description provided for @fieldPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get fieldPassword;

  /// No description provided for @rememberPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort auf dem Gerät merken'**
  String get rememberPassword;

  /// No description provided for @rememberPasswordHint.
  ///
  /// In de, this message translates to:
  /// **'Sonst nur Session-Token; Re-Login fragt neu.'**
  String get rememberPasswordHint;

  /// No description provided for @httpsInfo.
  ///
  /// In de, this message translates to:
  /// **'Nur HTTPS. Selbstsignierte Zertifikate werden beim ersten Verbinden per Fingerprint bestätigt.'**
  String get httpsInfo;

  /// No description provided for @httpWarning.
  ///
  /// In de, this message translates to:
  /// **'Unverschlüsselt (HTTP): Passwort und Dateien sind im Netz lesbar.'**
  String get httpWarning;

  /// No description provided for @connect.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get connect;

  /// No description provided for @validationRequired.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get validationRequired;

  /// No description provided for @validationUrl.
  ///
  /// In de, this message translates to:
  /// **'Keine gültige Adresse, z. B. https://192.168.178.20:5001'**
  String get validationUrl;

  /// No description provided for @certTitle.
  ///
  /// In de, this message translates to:
  /// **'Unbekanntes Zertifikat'**
  String get certTitle;

  /// No description provided for @certIntro.
  ///
  /// In de, this message translates to:
  /// **'Der Server {host} verwendet ein Zertifikat, dem dieses Gerät nicht vertraut (selbstsigniert oder unbekannte Zertifizierungsstelle). Vergleiche den Fingerprint mit DSM (Systemsteuerung › Sicherheit › Zertifikat), bevor du vertraust.'**
  String certIntro(String host);

  /// No description provided for @certSubject.
  ///
  /// In de, this message translates to:
  /// **'Ausgestellt für'**
  String get certSubject;

  /// No description provided for @certIssuer.
  ///
  /// In de, this message translates to:
  /// **'Aussteller'**
  String get certIssuer;

  /// No description provided for @certValidity.
  ///
  /// In de, this message translates to:
  /// **'Gültig'**
  String get certValidity;

  /// No description provided for @certFingerprint.
  ///
  /// In de, this message translates to:
  /// **'SHA-256-Fingerprint'**
  String get certFingerprint;

  /// No description provided for @certPinInfo.
  ///
  /// In de, this message translates to:
  /// **'Beim Vertrauen wird der Fingerprint gepinnt. Ändert er sich, blockiert die App die Verbindung.'**
  String get certPinInfo;

  /// No description provided for @certTrust.
  ///
  /// In de, this message translates to:
  /// **'Vertrauen'**
  String get certTrust;

  /// No description provided for @otpTitle.
  ///
  /// In de, this message translates to:
  /// **'Bestätigungscode'**
  String get otpTitle;

  /// No description provided for @otpHeading.
  ///
  /// In de, this message translates to:
  /// **'Zwei-Faktor-Authentifizierung'**
  String get otpHeading;

  /// No description provided for @otpIntro.
  ///
  /// In de, this message translates to:
  /// **'Gib den 6-stelligen Code aus deiner Authenticator-App für {account} ein.'**
  String otpIntro(String account);

  /// No description provided for @otpCode.
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get otpCode;

  /// No description provided for @otpRemember.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät merken'**
  String get otpRemember;

  /// No description provided for @otpRememberHint.
  ///
  /// In de, this message translates to:
  /// **'Fordert ein Geräte-Token an, kein Code beim nächsten Login.'**
  String get otpRememberHint;

  /// No description provided for @errorUnauthorized.
  ///
  /// In de, this message translates to:
  /// **'Benutzer oder Passwort falsch.'**
  String get errorUnauthorized;

  /// No description provided for @errorAccountLocked.
  ///
  /// In de, this message translates to:
  /// **'Konto gesperrt oder IP durch Auto-Block blockiert. Kein automatischer Neuversuch.'**
  String get errorAccountLocked;

  /// No description provided for @errorOtpRequired.
  ///
  /// In de, this message translates to:
  /// **'Bestätigungscode erforderlich.'**
  String get errorOtpRequired;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In de, this message translates to:
  /// **'Code ungültig oder abgelaufen. Kein automatischer Neuversuch (Auto-Block).'**
  String get errorOtpInvalid;

  /// No description provided for @errorSessionExpired.
  ///
  /// In de, this message translates to:
  /// **'Sitzung abgelaufen. Bitte neu anmelden.'**
  String get errorSessionExpired;

  /// No description provided for @errorPermission.
  ///
  /// In de, this message translates to:
  /// **'Keine Berechtigung.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In de, this message translates to:
  /// **'Nicht gefunden.'**
  String get errorNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar.'**
  String get errorNetwork;

  /// No description provided for @errorHttp.
  ///
  /// In de, this message translates to:
  /// **'Server antwortet mit HTTP {status}.'**
  String errorHttp(int status);

  /// No description provided for @errorCertMismatch.
  ///
  /// In de, this message translates to:
  /// **'Das Zertifikat von {host} hat sich geändert. Verbindung blockiert.'**
  String errorCertMismatch(String host);

  /// No description provided for @errorCode.
  ///
  /// In de, this message translates to:
  /// **'Fehler {code} vom NAS.'**
  String errorCode(int code);

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Unerwarteter Fehler.'**
  String get errorGeneric;

  /// No description provided for @sectionShares.
  ///
  /// In de, this message translates to:
  /// **'Freigegebene Ordner'**
  String get sectionShares;

  /// No description provided for @sectionFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get sectionFavorites;

  /// No description provided for @sectionRecent.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt geöffnet'**
  String get sectionRecent;

  /// No description provided for @permReadWrite.
  ///
  /// In de, this message translates to:
  /// **'Lesen/Schreiben'**
  String get permReadWrite;

  /// No description provided for @permReadOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Lesen'**
  String get permReadOnly;

  /// No description provided for @serverStatus.
  ///
  /// In de, this message translates to:
  /// **'{via} · {user}'**
  String serverStatus(String via, String user);

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @switchServer.
  ///
  /// In de, this message translates to:
  /// **'Server wechseln'**
  String get switchServer;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'heute {time}'**
  String today(String time);

  /// No description provided for @yesterday.
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get yesterday;

  /// No description provided for @datePattern.
  ///
  /// In de, this message translates to:
  /// **'dd.MM.yyyy'**
  String get datePattern;

  /// No description provided for @sortName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get sortDate;

  /// No description provided for @sortSize.
  ///
  /// In de, this message translates to:
  /// **'Größe'**
  String get sortSize;

  /// No description provided for @sortType.
  ///
  /// In de, this message translates to:
  /// **'Typ'**
  String get sortType;

  /// No description provided for @sortAscending.
  ///
  /// In de, this message translates to:
  /// **'Aufsteigend'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In de, this message translates to:
  /// **'Absteigend'**
  String get sortDescending;

  /// No description provided for @itemCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Element} other{{count} Elemente}}'**
  String itemCount(int count);

  /// No description provided for @folderEmpty.
  ///
  /// In de, this message translates to:
  /// **'Dieser Ordner ist leer.'**
  String get folderEmpty;

  /// No description provided for @viewGrid.
  ///
  /// In de, this message translates to:
  /// **'Rasteransicht'**
  String get viewGrid;

  /// No description provided for @viewList.
  ///
  /// In de, this message translates to:
  /// **'Listenansicht'**
  String get viewList;

  /// No description provided for @openLater.
  ///
  /// In de, this message translates to:
  /// **'Dateien öffnen kommt mit M2 (Audio) und M3 (Viewer).'**
  String get openLater;

  /// No description provided for @selectedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} ausgewählt'**
  String selectedCount(int count);

  /// No description provided for @actionOpen.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get actionOpen;

  /// No description provided for @actionPlayFromHere.
  ///
  /// In de, this message translates to:
  /// **'Abspielen ab hier'**
  String get actionPlayFromHere;

  /// No description provided for @actionPlayFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner abspielen (inkl. Unterordner)'**
  String get actionPlayFolder;

  /// No description provided for @actionQueue.
  ///
  /// In de, this message translates to:
  /// **'Zur Queue hinzufügen'**
  String get actionQueue;

  /// No description provided for @actionDownload.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get actionDownload;

  /// No description provided for @actionOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline verfügbar halten'**
  String get actionOffline;

  /// No description provided for @actionFavoriteAdd.
  ///
  /// In de, this message translates to:
  /// **'Zu Favoriten'**
  String get actionFavoriteAdd;

  /// No description provided for @actionFavoriteRemove.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get actionFavoriteRemove;

  /// No description provided for @actionShareLink.
  ///
  /// In de, this message translates to:
  /// **'Freigabelink erstellen'**
  String get actionShareLink;

  /// No description provided for @actionRename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get actionRename;

  /// No description provided for @actionMove.
  ///
  /// In de, this message translates to:
  /// **'Verschieben nach …'**
  String get actionMove;

  /// No description provided for @actionCopy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren nach …'**
  String get actionCopy;

  /// No description provided for @actionInfo.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get actionInfo;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen (in Papierkorb)'**
  String get actionDelete;

  /// No description provided for @availableFrom.
  ///
  /// In de, this message translates to:
  /// **'ab {milestone}'**
  String availableFrom(String milestone);

  /// No description provided for @infoPath.
  ///
  /// In de, this message translates to:
  /// **'Pfad'**
  String get infoPath;

  /// No description provided for @infoSize.
  ///
  /// In de, this message translates to:
  /// **'Größe'**
  String get infoSize;

  /// No description provided for @infoSizeBytes.
  ///
  /// In de, this message translates to:
  /// **'{size} ({bytes} Bytes)'**
  String infoSizeBytes(String size, String bytes);

  /// No description provided for @infoCreated.
  ///
  /// In de, this message translates to:
  /// **'Erstellt'**
  String get infoCreated;

  /// No description provided for @infoModified.
  ///
  /// In de, this message translates to:
  /// **'Geändert'**
  String get infoModified;

  /// No description provided for @infoOwner.
  ///
  /// In de, this message translates to:
  /// **'Besitzer'**
  String get infoOwner;

  /// No description provided for @infoPerm.
  ///
  /// In de, this message translates to:
  /// **'Rechte'**
  String get infoPerm;

  /// No description provided for @infoFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner'**
  String get infoFolder;

  /// No description provided for @computeSize.
  ///
  /// In de, this message translates to:
  /// **'Größe berechnen'**
  String get computeSize;

  /// No description provided for @dirSizeResult.
  ///
  /// In de, this message translates to:
  /// **'{size} · {files} Dateien · {dirs} Ordner'**
  String dirSizeResult(String size, String files, String dirs);

  /// No description provided for @copyPath.
  ///
  /// In de, this message translates to:
  /// **'Pfad kopieren'**
  String get copyPath;

  /// No description provided for @pathCopied.
  ///
  /// In de, this message translates to:
  /// **'Pfad kopiert'**
  String get pathCopied;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'Dateiname'**
  String get searchHint;

  /// No description provided for @searchIn.
  ///
  /// In de, this message translates to:
  /// **'Suche in {folder} (rekursiv)'**
  String searchIn(String folder);

  /// No description provided for @searchWholeNas.
  ///
  /// In de, this message translates to:
  /// **'Ganzes NAS'**
  String get searchWholeNas;

  /// No description provided for @searchAllShares.
  ///
  /// In de, this message translates to:
  /// **'Suche in allen freigegebenen Ordnern'**
  String get searchAllShares;

  /// No description provided for @filterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @filterAudio.
  ///
  /// In de, this message translates to:
  /// **'Audio'**
  String get filterAudio;

  /// No description provided for @filterImage.
  ///
  /// In de, this message translates to:
  /// **'Bilder'**
  String get filterImage;

  /// No description provided for @filterVideo.
  ///
  /// In de, this message translates to:
  /// **'Video'**
  String get filterVideo;

  /// No description provided for @filterDocument.
  ///
  /// In de, this message translates to:
  /// **'Dokumente'**
  String get filterDocument;

  /// No description provided for @searchRunning.
  ///
  /// In de, this message translates to:
  /// **'Suche läuft … {count} Treffer bisher'**
  String searchRunning(int count);

  /// No description provided for @searchDone.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Treffer} =1{1 Treffer} other{{count} Treffer}}'**
  String searchDone(int count);

  /// No description provided for @searchTruncated.
  ///
  /// In de, this message translates to:
  /// **'Die ersten {shown} von {total} Treffern – Suche verfeinern.'**
  String searchTruncated(int shown, int total);

  /// No description provided for @searchFooter.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Dateiname. Filter schränken auf Dateiendungen ein; beim Verlassen wird der Search-Task gestoppt und aufgeräumt.'**
  String get searchFooter;

  /// No description provided for @selectAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get selectAll;

  /// No description provided for @selectionSize.
  ///
  /// In de, this message translates to:
  /// **'Auswahl: {size}'**
  String selectionSize(String size);

  /// No description provided for @actionDownloadShort.
  ///
  /// In de, this message translates to:
  /// **'Download'**
  String get actionDownloadShort;

  /// No description provided for @actionMoveShort.
  ///
  /// In de, this message translates to:
  /// **'Verschieben'**
  String get actionMoveShort;

  /// No description provided for @actionCopyShort.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get actionCopyShort;

  /// No description provided for @actionShareShort.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get actionShareShort;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @create.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get share;

  /// No description provided for @pause.
  ///
  /// In de, this message translates to:
  /// **'Pausieren'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resume;

  /// No description provided for @validationName.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger Name (kein „/“).'**
  String get validationName;

  /// No description provided for @newFolder.
  ///
  /// In de, this message translates to:
  /// **'Neuer Ordner'**
  String get newFolder;

  /// No description provided for @newFolderHint.
  ///
  /// In de, this message translates to:
  /// **'Im aktuellen Verzeichnis'**
  String get newFolderHint;

  /// No description provided for @moveTo.
  ///
  /// In de, this message translates to:
  /// **'Verschieben nach …'**
  String get moveTo;

  /// No description provided for @copyTo.
  ///
  /// In de, this message translates to:
  /// **'Kopieren nach …'**
  String get copyTo;

  /// No description provided for @moveHere.
  ///
  /// In de, this message translates to:
  /// **'Hierher verschieben'**
  String get moveHere;

  /// No description provided for @copyHere.
  ///
  /// In de, this message translates to:
  /// **'Hierher kopieren'**
  String get copyHere;

  /// No description provided for @noSubfolders.
  ///
  /// In de, this message translates to:
  /// **'Keine Unterordner.'**
  String get noSubfolders;

  /// No description provided for @moving.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Verschiebe 1 Element …} other{Verschiebe {count} Elemente …}}'**
  String moving(int count);

  /// No description provided for @copying.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Kopiere 1 Element …} other{Kopiere {count} Elemente …}}'**
  String copying(int count);

  /// No description provided for @deleting.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Lösche 1 Element …} other{Lösche {count} Elemente …}}'**
  String deleting(int count);

  /// No description provided for @deleteConfirmOne.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ löschen?'**
  String deleteConfirmOne(String name);

  /// No description provided for @deleteConfirmMany.
  ///
  /// In de, this message translates to:
  /// **'{count} Elemente löschen?'**
  String deleteConfirmMany(int count);

  /// No description provided for @deleteToRecycle.
  ///
  /// In de, this message translates to:
  /// **'Die Freigabe hat einen Papierkorb: Gelöschtes lässt sich dort wiederherstellen.'**
  String get deleteToRecycle;

  /// No description provided for @deleteNoRecycle.
  ///
  /// In de, this message translates to:
  /// **'Die Freigabe hat keinen Papierkorb: Löschen ist endgültig.'**
  String get deleteNoRecycle;

  /// No description provided for @deleteRecycleUnknown.
  ///
  /// In de, this message translates to:
  /// **'Ob die Freigabe einen Papierkorb hat, ist nicht prüfbar (evtl. nur für Administratoren sichtbar). Im Zweifel ist Löschen endgültig.'**
  String get deleteRecycleUnknown;

  /// No description provided for @downloadsQueued.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Nichts herunterzuladen.} =1{1 Download eingereiht.} other{{count} Downloads eingereiht.}}'**
  String downloadsQueued(int count);

  /// No description provided for @uploadsQueued.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Upload eingereiht.} other{{count} Uploads eingereiht.}}'**
  String uploadsQueued(int count);

  /// No description provided for @uploadTitle.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get uploadTitle;

  /// No description provided for @uploadTarget.
  ///
  /// In de, this message translates to:
  /// **'Ziel: {path}'**
  String uploadTarget(String path);

  /// No description provided for @uploadFiles.
  ///
  /// In de, this message translates to:
  /// **'Dateien'**
  String get uploadFiles;

  /// No description provided for @uploadFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Aus dem System-Dateipicker'**
  String get uploadFilesHint;

  /// No description provided for @uploadMedia.
  ///
  /// In de, this message translates to:
  /// **'Fotos & Videos'**
  String get uploadMedia;

  /// No description provided for @uploadMediaHint.
  ///
  /// In de, this message translates to:
  /// **'Aus der Kamera-Rolle'**
  String get uploadMediaHint;

  /// No description provided for @uploadCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get uploadCamera;

  /// No description provided for @uploadCameraHint.
  ///
  /// In de, this message translates to:
  /// **'Aufnehmen und direkt hochladen'**
  String get uploadCameraHint;

  /// No description provided for @uploadOverwrite.
  ///
  /// In de, this message translates to:
  /// **'Vorhandene Dateien überschreiben'**
  String get uploadOverwrite;

  /// No description provided for @uploadOverwriteHint.
  ///
  /// In de, this message translates to:
  /// **'Sonst wird „ (1)“ angehängt'**
  String get uploadOverwriteHint;

  /// No description provided for @pauseAll.
  ///
  /// In de, this message translates to:
  /// **'Alle pausieren'**
  String get pauseAll;

  /// No description provided for @clearList.
  ///
  /// In de, this message translates to:
  /// **'Liste leeren'**
  String get clearList;

  /// No description provided for @transfersActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv ({count})'**
  String transfersActive(int count);

  /// No description provided for @transfersDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig ({count})'**
  String transfersDone(int count);

  /// No description provided for @transfersNone.
  ///
  /// In de, this message translates to:
  /// **'Keine laufenden Transfers.'**
  String get transfersNone;

  /// No description provided for @transfersNoneDone.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts fertig.'**
  String get transfersNoneDone;

  /// No description provided for @transfersFooter.
  ///
  /// In de, this message translates to:
  /// **'Die Queue überlebt einen App-Neustart. Downloads werden per HTTP-Range fortgesetzt, Uploads starten auf Datei-Ebene neu.'**
  String get transfersFooter;

  /// No description provided for @transferToOffline.
  ///
  /// In de, this message translates to:
  /// **'Download → Offline'**
  String get transferToOffline;

  /// No description provided for @transferToFolder.
  ///
  /// In de, this message translates to:
  /// **'Upload → {folder}'**
  String transferToFolder(String folder);

  /// No description provided for @transferQueued.
  ///
  /// In de, this message translates to:
  /// **'wartet'**
  String get transferQueued;

  /// No description provided for @transferPaused.
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get transferPaused;

  /// No description provided for @transferFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen: {reason}'**
  String transferFailed(String reason);

  /// No description provided for @bytesOf.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total}'**
  String bytesOf(String done, String total);

  /// No description provided for @remaining.
  ///
  /// In de, this message translates to:
  /// **'noch {time}'**
  String remaining(String time);

  /// No description provided for @durationSeconds.
  ///
  /// In de, this message translates to:
  /// **'{n} s'**
  String durationSeconds(int n);

  /// No description provided for @durationMinutes.
  ///
  /// In de, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// No description provided for @durationHours.
  ///
  /// In de, this message translates to:
  /// **'{n} h'**
  String durationHours(int n);

  /// No description provided for @resumesWithRange.
  ///
  /// In de, this message translates to:
  /// **'wird fortgesetzt (Range)'**
  String get resumesWithRange;

  /// No description provided for @notificationTransfers.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Transfer läuft} other{{count} Transfers laufen}}'**
  String notificationTransfers(int count);

  /// No description provided for @errorExists.
  ///
  /// In de, this message translates to:
  /// **'Ein Element mit diesem Namen gibt es dort schon.'**
  String get errorExists;

  /// No description provided for @errorLocalFile.
  ///
  /// In de, this message translates to:
  /// **'Lokale Datei nicht lesbar oder schreibbar.'**
  String get errorLocalFile;

  /// No description provided for @storageUsed.
  ///
  /// In de, this message translates to:
  /// **'Belegt auf diesem Gerät'**
  String get storageUsed;

  /// No description provided for @storageOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline-Dateien {size}'**
  String storageOffline(String size);

  /// No description provided for @storageCache.
  ///
  /// In de, this message translates to:
  /// **'Cache {size}'**
  String storageCache(String size);

  /// No description provided for @offlineInfo.
  ///
  /// In de, this message translates to:
  /// **'Alles hier ist ohne Verbindung nutzbar. Änderungen auf dem NAS werden beim nächsten Kontakt geprüft (mtime).'**
  String get offlineInfo;

  /// No description provided for @offlineEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Offline-Dateien. „Offline verfügbar halten“ im Datei-Menü lädt Dateien hierher.'**
  String get offlineEmpty;

  /// No description provided for @offlineChanged.
  ///
  /// In de, this message translates to:
  /// **'Auf dem NAS geändert – aktualisieren?'**
  String get offlineChanged;

  /// No description provided for @offlineRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get offlineRemove;

  /// No description provided for @moreItems.
  ///
  /// In de, this message translates to:
  /// **'+ {count} weitere'**
  String moreItems(int count);

  /// No description provided for @openFailed.
  ///
  /// In de, this message translates to:
  /// **'Keine App zum Öffnen gefunden.'**
  String get openFailed;

  /// No description provided for @shareLinkTitle.
  ///
  /// In de, this message translates to:
  /// **'Freigabelink'**
  String get shareLinkTitle;

  /// No description provided for @shareValidUntil.
  ///
  /// In de, this message translates to:
  /// **'Gültig bis'**
  String get shareValidUntil;

  /// No description provided for @expiryDay1.
  ///
  /// In de, this message translates to:
  /// **'1 Tag'**
  String get expiryDay1;

  /// No description provided for @expiryDays.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String expiryDays(int count);

  /// No description provided for @expiryNever.
  ///
  /// In de, this message translates to:
  /// **'Nie'**
  String get expiryNever;

  /// No description provided for @expiryNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Ablauf'**
  String get expiryNone;

  /// No description provided for @expiresOn.
  ///
  /// In de, this message translates to:
  /// **'Läuft ab am {date}'**
  String expiresOn(String date);

  /// No description provided for @expiresToday.
  ///
  /// In de, this message translates to:
  /// **'Läuft heute ab'**
  String get expiresToday;

  /// No description provided for @expiresInDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Läuft morgen ab} other{Läuft ab in {count} Tagen}}'**
  String expiresInDays(int count);

  /// No description provided for @expiredOn.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen am {date}'**
  String expiredOn(String date);

  /// No description provided for @sharePassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort (optional)'**
  String get sharePassword;

  /// No description provided for @generate.
  ///
  /// In de, this message translates to:
  /// **'Generieren'**
  String get generate;

  /// No description provided for @shareCreate.
  ///
  /// In de, this message translates to:
  /// **'Link erstellen'**
  String get shareCreate;

  /// No description provided for @shareCreated.
  ///
  /// In de, this message translates to:
  /// **'Link erstellt'**
  String get shareCreated;

  /// No description provided for @linkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert.'**
  String get linkCopied;

  /// No description provided for @shareExternalHint.
  ///
  /// In de, this message translates to:
  /// **'Der Link zeigt auf die externe Adresse. Verwaltung aller Links unter Einstellungen › Freigabelinks.'**
  String get shareExternalHint;

  /// No description provided for @shareNoExternal.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Server ist keine externe Adresse hinterlegt: Der Link nutzt die Adresse, die DSM meldet, und ist evtl. nur im LAN erreichbar.'**
  String get shareNoExternal;

  /// No description provided for @shareLinksTitle.
  ///
  /// In de, this message translates to:
  /// **'Freigabelinks'**
  String get shareLinksTitle;

  /// No description provided for @shareLinksCount.
  ///
  /// In de, this message translates to:
  /// **'{active} aktiv · {expired} abgelaufen'**
  String shareLinksCount(int active, int expired);

  /// No description provided for @shareLinksEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Freigabelinks.'**
  String get shareLinksEmpty;

  /// No description provided for @shareLinksFooter.
  ///
  /// In de, this message translates to:
  /// **'Quelle: SYNO.FileStation.Sharing list. Ablauf oder Passwort ändern geht über Link neu erstellen.'**
  String get shareLinksFooter;

  /// No description provided for @passwordBadge.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get passwordBadge;

  /// No description provided for @cleanUp.
  ///
  /// In de, this message translates to:
  /// **'Aufräumen'**
  String get cleanUp;

  /// No description provided for @trashTitle.
  ///
  /// In de, this message translates to:
  /// **'Papierkorb'**
  String get trashTitle;

  /// No description provided for @trashEmptyAction.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get trashEmptyAction;

  /// No description provided for @trashChecking.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Papierkörbe …'**
  String get trashChecking;

  /// No description provided for @trashInfo.
  ///
  /// In de, this message translates to:
  /// **'Zeigt #recycle der Freigabe.'**
  String get trashInfo;

  /// No description provided for @trashNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Papierkorb sichtbar.'**
  String get trashNone;

  /// No description provided for @trashHidden.
  ///
  /// In de, this message translates to:
  /// **'Fehlt: {shares} – dort ist der Papierkorb nur für Admins sichtbar.'**
  String trashHidden(String shares);

  /// No description provided for @trashIsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Der Papierkorb ist leer.'**
  String get trashIsEmpty;

  /// No description provided for @trashFooter.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen = Verschieben zurück an den Ursprungspfad (aus dem Papierkorb-Pfad abgeleitet). Endgültiges Löschen braucht eine zweite, rote Bestätigung.'**
  String get trashFooter;

  /// No description provided for @trashFrom.
  ///
  /// In de, this message translates to:
  /// **'aus {folder}'**
  String trashFrom(String folder);

  /// No description provided for @trashDeleted.
  ///
  /// In de, this message translates to:
  /// **'gelöscht {when}'**
  String trashDeleted(String when);

  /// No description provided for @restore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get restore;

  /// No description provided for @restoring.
  ///
  /// In de, this message translates to:
  /// **'Stelle wieder her …'**
  String get restoring;

  /// No description provided for @restored.
  ///
  /// In de, this message translates to:
  /// **'Wiederhergestellt nach {path}'**
  String restored(String path);

  /// No description provided for @deleteForever.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteForever;

  /// No description provided for @deleteForeverTitle.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen?'**
  String get deleteForeverTitle;

  /// No description provided for @deleteForeverOne.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ wird aus dem Papierkorb entfernt. Das kann nur noch ein Snapshot rückgängig machen.'**
  String deleteForeverOne(String name);

  /// No description provided for @deleteForeverMany.
  ///
  /// In de, this message translates to:
  /// **'{count} Elemente werden aus dem Papierkorb entfernt. Das kann nur noch ein Snapshot rückgängig machen.'**
  String deleteForeverMany(int count);

  /// No description provided for @actionDeleteShort.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDeleteShort;

  /// No description provided for @noWritePermission.
  ///
  /// In de, this message translates to:
  /// **'Keine Schreibrechte – das NAS lässt hier nur Lesen (und ggf. Löschen) zu.'**
  String get noWritePermission;

  /// No description provided for @export.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get export;

  /// No description provided for @viewerLoading.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get viewerLoading;

  /// No description provided for @downloadProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total}'**
  String downloadProgress(String done, String total);

  /// No description provided for @openWith.
  ///
  /// In de, this message translates to:
  /// **'Öffnen mit …'**
  String get openWith;

  /// No description provided for @openWithFailed.
  ///
  /// In de, this message translates to:
  /// **'Keine App zum Öffnen dieser Datei gefunden.'**
  String get openWithFailed;

  /// No description provided for @openWithHint.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Dateityp gibt es keine Vorschau in der App.'**
  String get openWithHint;

  /// No description provided for @textTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist größer als 5 MB und wird hier nicht angezeigt.'**
  String get textTooLarge;

  /// No description provided for @actionShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get actionShare;

  /// No description provided for @actionSaveToPhotos.
  ///
  /// In de, this message translates to:
  /// **'In Fotos'**
  String get actionSaveToPhotos;

  /// No description provided for @savedToPhotos.
  ///
  /// In de, this message translates to:
  /// **'In Fotos gespeichert'**
  String get savedToPhotos;

  /// No description provided for @actionFavorite.
  ///
  /// In de, this message translates to:
  /// **'Favorit'**
  String get actionFavorite;

  /// No description provided for @imageOf.
  ///
  /// In de, this message translates to:
  /// **'{index} von {total}'**
  String imageOf(String index, String total);

  /// No description provided for @heicUnavailable.
  ///
  /// In de, this message translates to:
  /// **'HEIC-Vorschau auf dem NAS nicht verfügbar'**
  String get heicUnavailable;

  /// No description provided for @imageUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Bild kann nicht angezeigt werden'**
  String get imageUnavailable;

  /// No description provided for @viewRendered.
  ///
  /// In de, this message translates to:
  /// **'Gerendert'**
  String get viewRendered;

  /// No description provided for @viewRaw.
  ///
  /// In de, this message translates to:
  /// **'Rohtext'**
  String get viewRaw;

  /// No description provided for @fontSize.
  ///
  /// In de, this message translates to:
  /// **'Schriftgröße'**
  String get fontSize;

  /// No description provided for @docxBanner.
  ///
  /// In de, this message translates to:
  /// **'Lesemodus: vereinfachte Darstellung. Seitenlayout, Kopfzeilen und Kommentare werden nicht gezeigt.'**
  String get docxBanner;

  /// No description provided for @docxUnreadable.
  ///
  /// In de, this message translates to:
  /// **'Das Dokument lässt sich im Lesemodus nicht anzeigen. „Öffnen mit …“ übergibt es an eine andere App.'**
  String get docxUnreadable;

  /// No description provided for @pdfPage.
  ///
  /// In de, this message translates to:
  /// **'Seite'**
  String get pdfPage;

  /// No description provided for @pdfOfTotal.
  ///
  /// In de, this message translates to:
  /// **'von {total}'**
  String pdfOfTotal(String total);

  /// No description provided for @pdfPrevious.
  ///
  /// In de, this message translates to:
  /// **'Vorherige Seite'**
  String get pdfPrevious;

  /// No description provided for @pdfNext.
  ///
  /// In de, this message translates to:
  /// **'Nächste Seite'**
  String get pdfNext;

  /// No description provided for @searchInDocument.
  ///
  /// In de, this message translates to:
  /// **'Im Dokument suchen'**
  String get searchInDocument;

  /// No description provided for @noMatches.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer'**
  String get noMatches;

  /// No description provided for @previousMatch.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Treffer'**
  String get previousMatch;

  /// No description provided for @nextMatch.
  ///
  /// In de, this message translates to:
  /// **'Nächster Treffer'**
  String get nextMatch;

  /// No description provided for @resumeAt.
  ///
  /// In de, this message translates to:
  /// **'Bei {time} fortsetzen?'**
  String resumeAt(String time);

  /// No description provided for @restart.
  ///
  /// In de, this message translates to:
  /// **'Von vorn'**
  String get restart;

  /// No description provided for @subtitles.
  ///
  /// In de, this message translates to:
  /// **'Untertitel'**
  String get subtitles;

  /// No description provided for @speed.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit'**
  String get speed;

  /// No description provided for @rewind10.
  ///
  /// In de, this message translates to:
  /// **'10 s zurück'**
  String get rewind10;

  /// No description provided for @forward10.
  ///
  /// In de, this message translates to:
  /// **'10 s vor'**
  String get forward10;

  /// No description provided for @play.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get play;

  /// No description provided for @volumePercent.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke {percent} %'**
  String volumePercent(String percent);

  /// No description provided for @brightnessPercent.
  ///
  /// In de, this message translates to:
  /// **'Helligkeit {percent} %'**
  String brightnessPercent(String percent);

  /// No description provided for @fullscreen.
  ///
  /// In de, this message translates to:
  /// **'Vollbild umschalten'**
  String get fullscreen;

  /// No description provided for @videoUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Video kann nicht abgespielt werden'**
  String get videoUnavailable;

  /// No description provided for @audioChannelName.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe'**
  String get audioChannelName;

  /// No description provided for @playFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner abspielen'**
  String get playFolder;

  /// No description provided for @playingFromFolder.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe aus Ordner'**
  String get playingFromFolder;

  /// No description provided for @trackOf.
  ///
  /// In de, this message translates to:
  /// **'Titel {index} von {count}'**
  String trackOf(int index, int count);

  /// No description provided for @nowPlayingRow.
  ///
  /// In de, this message translates to:
  /// **'läuft gerade'**
  String get nowPlayingRow;

  /// No description provided for @queueTitle.
  ///
  /// In de, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @queueButton.
  ///
  /// In de, this message translates to:
  /// **'Queue ({count})'**
  String queueButton(int count);

  /// No description provided for @queueClear.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get queueClear;

  /// No description provided for @queueNowPlaying.
  ///
  /// In de, this message translates to:
  /// **'Läuft gerade'**
  String get queueNowPlaying;

  /// No description provided for @queueUpNext.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Als Nächstes · keine Titel} =1{Als Nächstes · 1 Titel} other{Als Nächstes · {count} Titel}}'**
  String queueUpNext(int count);

  /// No description provided for @queueHint.
  ///
  /// In de, this message translates to:
  /// **'{played, plural, =0{Wischen nach links entfernt, Handle zieht.} =1{1 Titel wurde bereits gespielt. Wischen nach links entfernt, Handle zieht.} other{{played} Titel wurden bereits gespielt. Wischen nach links entfernt, Handle zieht.}}'**
  String queueHint(int played);

  /// No description provided for @queueRemove.
  ///
  /// In de, this message translates to:
  /// **'Aus der Queue entfernen'**
  String get queueRemove;

  /// No description provided for @queueAdded.
  ///
  /// In de, this message translates to:
  /// **'Zur Queue hinzugefügt'**
  String get queueAdded;

  /// No description provided for @noAudioInFolder.
  ///
  /// In de, this message translates to:
  /// **'Keine Audiodateien in diesem Ordner.'**
  String get noAudioInFolder;

  /// No description provided for @nextTrack.
  ///
  /// In de, this message translates to:
  /// **'Nächster Titel'**
  String get nextTrack;

  /// No description provided for @previousTrack.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Titel'**
  String get previousTrack;

  /// No description provided for @collapse.
  ///
  /// In de, this message translates to:
  /// **'Einklappen'**
  String get collapse;

  /// No description provided for @shuffleOn.
  ///
  /// In de, this message translates to:
  /// **'Zufallswiedergabe an'**
  String get shuffleOn;

  /// No description provided for @shuffleOff.
  ///
  /// In de, this message translates to:
  /// **'Zufallswiedergabe aus'**
  String get shuffleOff;

  /// No description provided for @repeatOff.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen aus'**
  String get repeatOff;

  /// No description provided for @repeatOne.
  ///
  /// In de, this message translates to:
  /// **'Titel wiederholen'**
  String get repeatOne;

  /// No description provided for @repeatAll.
  ///
  /// In de, this message translates to:
  /// **'Ordner wiederholen'**
  String get repeatAll;

  /// No description provided for @repeatSummaryOff.
  ///
  /// In de, this message translates to:
  /// **'Ordner · einmal'**
  String get repeatSummaryOff;

  /// No description provided for @repeatSummaryOne.
  ///
  /// In de, this message translates to:
  /// **'Titel · Wiederholen'**
  String get repeatSummaryOne;

  /// No description provided for @repeatSummaryAll.
  ///
  /// In de, this message translates to:
  /// **'Ordner · Wiederholen'**
  String get repeatSummaryAll;

  /// No description provided for @shuffleSummary.
  ///
  /// In de, this message translates to:
  /// **'Zufällig'**
  String get shuffleSummary;

  /// No description provided for @speedTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit'**
  String get speedTitle;

  /// No description provided for @speedValue.
  ///
  /// In de, this message translates to:
  /// **'{speed}×'**
  String speedValue(String speed);

  /// No description provided for @sleep.
  ///
  /// In de, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @sleepTitle.
  ///
  /// In de, this message translates to:
  /// **'Sleep-Timer'**
  String get sleepTitle;

  /// No description provided for @sleepMinutes.
  ///
  /// In de, this message translates to:
  /// **'Sleep {minutes} min'**
  String sleepMinutes(int minutes);

  /// No description provided for @sleepEndOfTrackShort.
  ///
  /// In de, this message translates to:
  /// **'Sleep: Titelende'**
  String get sleepEndOfTrackShort;

  /// No description provided for @sleepOption.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Minuten'**
  String sleepOption(int minutes);

  /// No description provided for @sleepEndOfTrack.
  ///
  /// In de, this message translates to:
  /// **'Ende des Titels'**
  String get sleepEndOfTrack;

  /// No description provided for @sleepOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get sleepOff;

  /// No description provided for @resumeAction.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resumeAction;

  /// No description provided for @errorWifiRequired.
  ///
  /// In de, this message translates to:
  /// **'Streaming nur im WLAN – gerade keine WLAN-Verbindung.'**
  String get errorWifiRequired;

  /// No description provided for @errorNotPlayable.
  ///
  /// In de, this message translates to:
  /// **'Nicht abspielbar: Das Format wird auf diesem Gerät nicht unterstützt.'**
  String get errorNotPlayable;

  /// No description provided for @audiobookMode.
  ///
  /// In de, this message translates to:
  /// **'Hörbuch-Modus'**
  String get audiobookMode;

  /// No description provided for @audiobookModeHint.
  ///
  /// In de, this message translates to:
  /// **'Merkt sich Titel und Position im Ordner'**
  String get audiobookModeHint;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In de, this message translates to:
  /// **'Streaming nur im WLAN'**
  String get settingsWifiOnly;

  /// No description provided for @settingsWifiOnlyHint.
  ///
  /// In de, this message translates to:
  /// **'Über Mobilfunk wird nicht gestreamt.'**
  String get settingsWifiOnlyHint;

  /// No description provided for @errorStreamFailed.
  ///
  /// In de, this message translates to:
  /// **'Datei konnte nicht geladen werden – Verbindung zum NAS prüfen.'**
  String get errorStreamFailed;

  /// No description provided for @playFolderShort.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get playFolderShort;

  /// No description provided for @settingsSectionConnection.
  ///
  /// In de, this message translates to:
  /// **'Verbindung'**
  String get settingsSectionConnection;

  /// No description provided for @settingsServers.
  ///
  /// In de, this message translates to:
  /// **'Server verwalten'**
  String get settingsServers;

  /// No description provided for @settingsLinksActive.
  ///
  /// In de, this message translates to:
  /// **'{count} aktiv'**
  String settingsLinksActive(int count);

  /// No description provided for @settingsNeedsServer.
  ///
  /// In de, this message translates to:
  /// **'Dafür zuerst mit einem Server verbinden.'**
  String get settingsNeedsServer;

  /// No description provided for @settingsSectionMedia.
  ///
  /// In de, this message translates to:
  /// **'Medien & Speicher'**
  String get settingsSectionMedia;

  /// No description provided for @settingsOn.
  ///
  /// In de, this message translates to:
  /// **'An'**
  String get settingsOn;

  /// No description provided for @settingsOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get settingsOff;

  /// No description provided for @settingsPlayback.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe'**
  String get settingsPlayback;

  /// No description provided for @settingsPlaybackHint.
  ///
  /// In de, this message translates to:
  /// **'Resume, Sleep-Timer'**
  String get settingsPlaybackHint;

  /// No description provided for @playbackInfo.
  ///
  /// In de, this message translates to:
  /// **'Die App merkt sich die Position jeder Audio- und Videodatei und bietet beim nächsten Öffnen „Fortsetzen“ an. Sleep-Timer und Geschwindigkeit stellst du im Player ein.'**
  String get playbackInfo;

  /// No description provided for @playbackClearPositions.
  ///
  /// In de, this message translates to:
  /// **'Gemerkte Positionen löschen ({count})'**
  String playbackClearPositions(int count);

  /// No description provided for @playbackPositionsCleared.
  ///
  /// In de, this message translates to:
  /// **'Positionen gelöscht.'**
  String get playbackPositionsCleared;

  /// No description provided for @settingsCacheLimit.
  ///
  /// In de, this message translates to:
  /// **'Cache-Limit'**
  String get settingsCacheLimit;

  /// No description provided for @settingsCacheValue.
  ///
  /// In de, this message translates to:
  /// **'{limit} · {used} belegt'**
  String settingsCacheValue(String limit, String used);

  /// No description provided for @settingsCacheHint.
  ///
  /// In de, this message translates to:
  /// **'Gilt für gestreamte Medien, Dokumente und Vorschaubilder. Am längsten nicht Genutztes wird zuerst verdrängt.'**
  String get settingsCacheHint;

  /// No description provided for @cacheClear.
  ///
  /// In de, this message translates to:
  /// **'Cache leeren'**
  String get cacheClear;

  /// No description provided for @cacheCleared.
  ///
  /// In de, this message translates to:
  /// **'Cache geleert.'**
  String get cacheCleared;

  /// No description provided for @settingsOfflineStorage.
  ///
  /// In de, this message translates to:
  /// **'Offline-Speicher'**
  String get settingsOfflineStorage;

  /// No description provided for @settingsSectionApp.
  ///
  /// In de, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsDesign.
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get settingsDesign;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'{language} (System)'**
  String languageSystem(String language);

  /// No description provided for @languageSystemOption.
  ///
  /// In de, this message translates to:
  /// **'Systemsprache'**
  String get languageSystemOption;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über & Lizenzen'**
  String get settingsAbout;

  /// No description provided for @aboutLegalese.
  ///
  /// In de, this message translates to:
  /// **'Freie Software (CC0), kein Produkt der Synology Inc. Die App sendet keine Daten an Dritte. Die Videowiedergabe nutzt media_kit mit libmpv und FFmpeg (LGPL 2.1 oder neuer); Quelltext und Lizenzen unter github.com/media-kit/media-kit.'**
  String get aboutLegalese;

  /// No description provided for @settingsClearAll.
  ///
  /// In de, this message translates to:
  /// **'Alle lokalen Daten löschen'**
  String get settingsClearAll;

  /// No description provided for @settingsClearAllHint.
  ///
  /// In de, this message translates to:
  /// **'Cache, Offline, Tokens'**
  String get settingsClearAllHint;

  /// No description provided for @settingsClearAllConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle lokalen Daten löschen?'**
  String get settingsClearAllConfirm;

  /// No description provided for @settingsClearAllBody.
  ///
  /// In de, this message translates to:
  /// **'Gelöscht werden Cache, Offline-Dateien und Transfers sowie Anmeldungen, Geräte-Token, gemerkte Passwörter und bestätigte Zertifikate. Server-Profile und Einstellungen bleiben; danach meldest du dich neu an.'**
  String get settingsClearAllBody;

  /// No description provided for @settingsClearAllAction.
  ///
  /// In de, this message translates to:
  /// **'Alles löschen'**
  String get settingsClearAllAction;

  /// No description provided for @settingsCleared.
  ///
  /// In de, this message translates to:
  /// **'Lokale Daten gelöscht.'**
  String get settingsCleared;

  /// No description provided for @autoUploadTitle.
  ///
  /// In de, this message translates to:
  /// **'Auto-Upload'**
  String get autoUploadTitle;

  /// No description provided for @autoUploadHeroTitle.
  ///
  /// In de, this message translates to:
  /// **'Fotos & Videos sichern'**
  String get autoUploadHeroTitle;

  /// No description provided for @autoUploadHeroSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Aufnahmen aus der Kamera-Rolle'**
  String get autoUploadHeroSubtitle;

  /// No description provided for @autoUploadEnabled.
  ///
  /// In de, this message translates to:
  /// **'Neue Aufnahmen werden ab jetzt gesichert.'**
  String get autoUploadEnabled;

  /// No description provided for @autoUploadTarget.
  ///
  /// In de, this message translates to:
  /// **'Zielordner'**
  String get autoUploadTarget;

  /// No description provided for @autoUploadTargetNone.
  ///
  /// In de, this message translates to:
  /// **'Nicht gewählt'**
  String get autoUploadTargetNone;

  /// No description provided for @autoUploadPickConfirm.
  ///
  /// In de, this message translates to:
  /// **'Hier sichern'**
  String get autoUploadPickConfirm;

  /// No description provided for @autoUploadNeedsSession.
  ///
  /// In de, this message translates to:
  /// **'Zum Wählen des Zielordners zuerst mit dem Server verbinden.'**
  String get autoUploadNeedsSession;

  /// No description provided for @autoUploadScheme.
  ///
  /// In de, this message translates to:
  /// **'Ordnerschema'**
  String get autoUploadScheme;

  /// No description provided for @schemeYearMonth.
  ///
  /// In de, this message translates to:
  /// **'Jahr / Monat'**
  String get schemeYearMonth;

  /// No description provided for @schemeYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get schemeYear;

  /// No description provided for @schemeFlat.
  ///
  /// In de, this message translates to:
  /// **'Keine Unterordner'**
  String get schemeFlat;

  /// No description provided for @autoUploadWifiOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur im WLAN'**
  String get autoUploadWifiOnly;

  /// No description provided for @autoUploadWifiOnlyHint.
  ///
  /// In de, this message translates to:
  /// **'Auch bei aktivem VPN über Mobilfunk pausieren'**
  String get autoUploadWifiOnlyHint;

  /// No description provided for @autoUploadVideos.
  ///
  /// In de, this message translates to:
  /// **'Videos einschließen'**
  String get autoUploadVideos;

  /// No description provided for @autoUploadVideosHint.
  ///
  /// In de, this message translates to:
  /// **'Kann viel Volumen erzeugen'**
  String get autoUploadVideosHint;

  /// No description provided for @autoUploadCharging.
  ///
  /// In de, this message translates to:
  /// **'Nur beim Laden'**
  String get autoUploadCharging;

  /// No description provided for @autoUploadChargingHint.
  ///
  /// In de, this message translates to:
  /// **'Schont Akku bei großen Rückständen'**
  String get autoUploadChargingHint;

  /// No description provided for @autoUploadPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Ohne Zugriff auf alle Fotos kann der Auto-Upload nichts sichern. Du kannst den Zugriff in den Systemeinstellungen erlauben.'**
  String get autoUploadPermissionDenied;

  /// No description provided for @openSystemSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get openSystemSettings;

  /// No description provided for @autoUploadStatus.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get autoUploadStatus;

  /// No description provided for @autoUploadLastRun.
  ///
  /// In de, this message translates to:
  /// **'Letzter Lauf {when} · {files, plural, =1{1 Datei} other{{files} Dateien}} · {failed} Fehler'**
  String autoUploadLastRun(String when, int files, int failed);

  /// No description provided for @autoUploadNeverRun.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts gesichert'**
  String get autoUploadNeverRun;

  /// No description provided for @autoUploadRunning.
  ///
  /// In de, this message translates to:
  /// **'Läuft …'**
  String get autoUploadRunning;

  /// No description provided for @autoUploadLastCheck.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt geprüft {when}'**
  String autoUploadLastCheck(String when);

  /// No description provided for @autoUploadTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamt gesichert: {files} Dateien · {size}'**
  String autoUploadTotal(String files, String size);

  /// No description provided for @autoUploadRunNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt ausführen'**
  String get autoUploadRunNow;

  /// No description provided for @autoUploadLog.
  ///
  /// In de, this message translates to:
  /// **'Protokoll'**
  String get autoUploadLog;

  /// No description provided for @autoUploadLogEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge.'**
  String get autoUploadLogEmpty;

  /// No description provided for @autoUploadRunSummary.
  ///
  /// In de, this message translates to:
  /// **'{files, plural, =1{1 Datei} other{{files} Dateien}} · {failed} Fehler · {size}'**
  String autoUploadRunSummary(int files, int failed, String size);

  /// No description provided for @autoUploadWaitingWifi.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Datei wartet} other{{count} Dateien warten}} auf WLAN'**
  String autoUploadWaitingWifi(int count);

  /// No description provided for @autoUploadWaitingCharging.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Datei wartet} other{{count} Dateien warten}} aufs Laden'**
  String autoUploadWaitingCharging(int count);

  /// No description provided for @autoUploadNoteUnreachable.
  ///
  /// In de, this message translates to:
  /// **'NAS nicht erreichbar – {count, plural, =1{1 Datei wartet} other{{count} Dateien warten}}'**
  String autoUploadNoteUnreachable(int count);

  /// No description provided for @autoUploadNoteOtherServer.
  ///
  /// In de, this message translates to:
  /// **'Anderer Server angemeldet – {count, plural, =1{1 Datei wartet} other{{count} Dateien warten}}'**
  String autoUploadNoteOtherServer(int count);

  /// No description provided for @autoUploadNoteSession.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung abgelaufen – bitte in der App neu anmelden'**
  String get autoUploadNoteSession;

  /// No description provided for @autoUploadNoteWrite.
  ///
  /// In de, this message translates to:
  /// **'Keine Schreibrechte im Zielordner – anderen Ordner wählen oder Rechte in DSM anpassen'**
  String get autoUploadNoteWrite;

  /// No description provided for @autoUploadNoteTarget.
  ///
  /// In de, this message translates to:
  /// **'Zielordner nicht gefunden'**
  String get autoUploadNoteTarget;

  /// No description provided for @autoUploadNotePermission.
  ///
  /// In de, this message translates to:
  /// **'Kein Zugriff auf Fotos – in den Systemeinstellungen erlauben'**
  String get autoUploadNotePermission;

  /// No description provided for @autoUploadNoteError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim letzten Lauf'**
  String get autoUploadNoteError;

  /// No description provided for @autoUploadIosHint.
  ///
  /// In de, this message translates to:
  /// **'Auf dem iPhone läuft der Upload im Hintergrund nur, wenn das System es zulässt; beim Öffnen der App wird nachgeholt.'**
  String get autoUploadIosHint;

  /// No description provided for @autoUploadNotification.
  ///
  /// In de, this message translates to:
  /// **'Auto-Upload'**
  String get autoUploadNotification;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
