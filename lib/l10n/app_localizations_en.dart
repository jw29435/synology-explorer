// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Synology Explorer';

  @override
  String get tabFiles => 'Files';

  @override
  String get tabOffline => 'Offline';

  @override
  String get tabTransfers => 'Transfers';

  @override
  String get tabSettings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Try again';

  @override
  String get signIn => 'Sign in';

  @override
  String get more => 'More';

  @override
  String get serversTitle => 'Servers';

  @override
  String get serverAdd => 'Add server';

  @override
  String get serverEditTitle => 'Edit server';

  @override
  String get serversEmpty => 'No server set up yet.';

  @override
  String serverConnectedVia(String via) {
    return 'Connected via $via';
  }

  @override
  String get viaLan => 'LAN';

  @override
  String get viaExternal => 'external';

  @override
  String get serverNotConnected => 'Not connected';

  @override
  String get serverInfo =>
      'The LAN address is tried first, then the external one. QuickConnect is not supported.';

  @override
  String get serverEdit => 'Edit';

  @override
  String get serverLogout => 'Sign out';

  @override
  String get serverDelete => 'Delete';

  @override
  String serverDeleteConfirm(String name) {
    return 'Delete “$name”? Favorites and history of this server will be removed.';
  }

  @override
  String get fieldName => 'Name';

  @override
  String get fieldLanUrl => 'LAN address';

  @override
  String get fieldLanUrlHint => 'Tried first, 2 s timeout.';

  @override
  String get fieldExternalUrl => 'External address (optional)';

  @override
  String get fieldExternalUrlHint =>
      'DDNS, reverse proxy or Tailscale address.';

  @override
  String get fieldUser => 'User';

  @override
  String get fieldPassword => 'Password';

  @override
  String get rememberPassword => 'Remember password on this device';

  @override
  String get rememberPasswordHint =>
      'Otherwise only a session token; re-login asks again.';

  @override
  String get httpsInfo =>
      'HTTPS only. Self-signed certificates are confirmed by fingerprint on first connect.';

  @override
  String get httpWarning =>
      'Unencrypted (HTTP): password and files are readable on the network.';

  @override
  String get connect => 'Connect';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationUrl =>
      'Not a valid address, e.g. https://192.168.178.20:5001';

  @override
  String get certTitle => 'Unknown certificate';

  @override
  String certIntro(String host) {
    return 'The server $host uses a certificate this device does not trust (self-signed or unknown certificate authority). Compare the fingerprint with DSM (Control Panel › Security › Certificate) before you trust it.';
  }

  @override
  String get certSubject => 'Issued to';

  @override
  String get certIssuer => 'Issuer';

  @override
  String get certValidity => 'Valid';

  @override
  String get certFingerprint => 'SHA-256 fingerprint';

  @override
  String get certPinInfo =>
      'Trusting pins the fingerprint. If it changes, the app blocks the connection.';

  @override
  String get certTrust => 'Trust';

  @override
  String get otpTitle => 'Verification code';

  @override
  String get otpHeading => 'Two-factor authentication';

  @override
  String otpIntro(String account) {
    return 'Enter the 6-digit code from your authenticator app for $account.';
  }

  @override
  String get otpCode => 'Code';

  @override
  String get otpRemember => 'Remember this device';

  @override
  String get otpRememberHint =>
      'Requests a device token, no code on next sign-in.';

  @override
  String get errorUnauthorized => 'Wrong user name or password.';

  @override
  String get errorAccountLocked =>
      'Account disabled or IP blocked by auto block. No automatic retry.';

  @override
  String get errorOtpRequired => 'Verification code required.';

  @override
  String get errorOtpInvalid =>
      'Code invalid or expired. No automatic retry (auto block).';

  @override
  String get errorSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get errorPermission => 'Permission denied.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorNetwork => 'Server not reachable.';

  @override
  String errorHttp(int status) {
    return 'Server responded with HTTP $status.';
  }

  @override
  String errorCertMismatch(String host) {
    return 'The certificate of $host has changed. Connection blocked.';
  }

  @override
  String errorCode(int code) {
    return 'Error $code from the NAS.';
  }

  @override
  String get errorGeneric => 'Unexpected error.';

  @override
  String get sectionShares => 'Shared folders';

  @override
  String get sectionFavorites => 'Favorites';

  @override
  String get sectionRecent => 'Recently opened';

  @override
  String get permReadWrite => 'Read/write';

  @override
  String get permReadOnly => 'Read only';

  @override
  String serverStatus(String via, String user) {
    return '$via · $user';
  }

  @override
  String get search => 'Search';

  @override
  String get switchServer => 'Switch server';

  @override
  String today(String time) {
    return 'today $time';
  }

  @override
  String get yesterday => 'yesterday';

  @override
  String get datePattern => 'MM/dd/yyyy';

  @override
  String get sortName => 'Name';

  @override
  String get sortDate => 'Date';

  @override
  String get sortSize => 'Size';

  @override
  String get sortType => 'Type';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get folderEmpty => 'This folder is empty.';

  @override
  String get viewGrid => 'Grid view';

  @override
  String get viewList => 'List view';

  @override
  String get fabLater => 'Upload and new folders come with M4.';

  @override
  String get openLater =>
      'Opening files comes with M2 (audio) and M3 (viewers).';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get actionOpen => 'Open';

  @override
  String get actionPlayFromHere => 'Play from here';

  @override
  String get actionPlayFolder => 'Play folder (incl. subfolders)';

  @override
  String get actionQueue => 'Add to queue';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionOffline => 'Keep available offline';

  @override
  String get actionFavoriteAdd => 'Add to favorites';

  @override
  String get actionFavoriteRemove => 'Remove from favorites';

  @override
  String get actionShareLink => 'Create share link';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionMove => 'Move to …';

  @override
  String get actionCopy => 'Copy to …';

  @override
  String get actionInfo => 'Info';

  @override
  String get actionDelete => 'Delete (to recycle bin)';

  @override
  String availableFrom(String milestone) {
    return 'from $milestone';
  }

  @override
  String get infoPath => 'Path';

  @override
  String get infoSize => 'Size';

  @override
  String infoSizeBytes(String size, String bytes) {
    return '$size ($bytes bytes)';
  }

  @override
  String get infoCreated => 'Created';

  @override
  String get infoModified => 'Modified';

  @override
  String get infoOwner => 'Owner';

  @override
  String get infoPerm => 'Permissions';

  @override
  String get infoFolder => 'Folder';

  @override
  String get computeSize => 'Calculate size';

  @override
  String dirSizeResult(String size, String files, String dirs) {
    return '$size · $files files · $dirs folders';
  }

  @override
  String get copyPath => 'Copy path';

  @override
  String get pathCopied => 'Path copied';

  @override
  String get searchHint => 'File name';

  @override
  String searchIn(String folder) {
    return 'Searching $folder (recursive)';
  }

  @override
  String get searchWholeNas => 'Whole NAS';

  @override
  String get searchAllShares => 'Searching all shared folders';

  @override
  String get filterAll => 'All';

  @override
  String get filterAudio => 'Audio';

  @override
  String get filterImage => 'Images';

  @override
  String get filterVideo => 'Video';

  @override
  String get filterDocument => 'Documents';

  @override
  String searchRunning(int count) {
    return 'Searching … $count hits so far';
  }

  @override
  String searchDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hits',
      one: '1 hit',
      zero: 'No hits',
    );
    return '$_temp0';
  }

  @override
  String searchTruncated(int shown, int total) {
    return 'First $shown of $total hits – refine your search.';
  }

  @override
  String get searchFooter =>
      'Searches file names. Filters restrict file extensions; leaving stops and cleans up the search task.';
}
