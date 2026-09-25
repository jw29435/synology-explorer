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

  /// No description provided for @fabLater.
  ///
  /// In de, this message translates to:
  /// **'Hochladen und neue Ordner kommen mit M4.'**
  String get fabLater;

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
