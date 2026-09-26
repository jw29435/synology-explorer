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
  String get serverManageHint => 'Press and hold to edit, sign out or delete.';

  @override
  String get serverManageAction => 'Edit, sign out, delete';

  @override
  String get serverResuming => 'Connecting to the last used server …';

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
  String errorCertUntrusted(String host) {
    return '$host uses an unknown certificate. Reconnect from the server list and check it there.';
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
  String get sharesEmpty =>
      'No shared folders visible. Check in DSM that the account has read access to shares and may use File Station.';

  @override
  String get sectionFavorites => 'Favorites';

  @override
  String get sectionRecent => 'Recently opened';

  @override
  String get favoriteBroken => 'No longer on the NAS';

  @override
  String get favoritesUnavailable =>
      'Favorites are not available for this account.';

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
  String get infoType => 'Type';

  @override
  String infoTypeValue(String ext, String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'audio': 'audio',
      'image': 'image',
      'video': 'video',
      'document': 'document',
      'other': 'file',
    });
    return '$ext $_temp0';
  }

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

  @override
  String get selectAll => 'All';

  @override
  String selectionSize(String size) {
    return 'Selection: $size';
  }

  @override
  String get actionDownloadShort => 'Download';

  @override
  String get actionMoveShort => 'Move';

  @override
  String get actionCopyShort => 'Copy';

  @override
  String get actionShareShort => 'Share';

  @override
  String get back => 'Back';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get validationName => 'Invalid name (no “/”).';

  @override
  String get newFolder => 'New folder';

  @override
  String get newFolderHint => 'In the current folder';

  @override
  String get moveTo => 'Move to …';

  @override
  String get copyTo => 'Copy to …';

  @override
  String get moveHere => 'Move here';

  @override
  String get copyHere => 'Copy here';

  @override
  String get noSubfolders => 'No subfolders.';

  @override
  String moving(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moving $count items …',
      one: 'Moving 1 item …',
    );
    return '$_temp0';
  }

  @override
  String copying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copying $count items …',
      one: 'Copying 1 item …',
    );
    return '$_temp0';
  }

  @override
  String deleting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleting $count items …',
      one: 'Deleting 1 item …',
    );
    return '$_temp0';
  }

  @override
  String deleteConfirmOne(String name) {
    return 'Delete “$name”?';
  }

  @override
  String deleteConfirmMany(int count) {
    return 'Delete $count items?';
  }

  @override
  String get deleteToRecycle =>
      'This shared folder has a recycle bin: deleted items can be restored from there.';

  @override
  String get deleteNoRecycle =>
      'This shared folder has no recycle bin: deleting is permanent.';

  @override
  String get deleteRecycleUnknown =>
      'Cannot check whether this shared folder has a recycle bin (it may be visible to administrators only). If in doubt, deleting is permanent.';

  @override
  String downloadsQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads queued.',
      one: '1 download queued.',
      zero: 'Nothing to download.',
    );
    return '$_temp0';
  }

  @override
  String uploadsQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uploads queued.',
      one: '1 upload queued.',
    );
    return '$_temp0';
  }

  @override
  String get uploadTitle => 'Add';

  @override
  String uploadTarget(String path) {
    return 'Target: $path';
  }

  @override
  String get uploadFiles => 'Files';

  @override
  String get uploadFilesHint => 'From the system file picker';

  @override
  String get uploadMedia => 'Photos & videos';

  @override
  String get uploadMediaHint => 'From the camera roll';

  @override
  String get uploadCamera => 'Camera';

  @override
  String get uploadCameraHint => 'Take a photo and upload it';

  @override
  String get uploadOverwrite => 'Overwrite existing files';

  @override
  String get uploadOverwriteHint => 'Otherwise “ (1)” is appended';

  @override
  String get pauseAll => 'Pause all';

  @override
  String get clearList => 'Clear list';

  @override
  String transfersActive(int count) {
    return 'Active ($count)';
  }

  @override
  String transfersDone(int count) {
    return 'Done ($count)';
  }

  @override
  String get transfersNone => 'No active transfers.';

  @override
  String get transfersNoneDone => 'Nothing finished yet.';

  @override
  String get transfersFooter =>
      'The queue survives an app restart. Downloads resume via HTTP range, uploads restart per file.';

  @override
  String get transferToOffline => 'Download → Offline';

  @override
  String transferToFolder(String folder) {
    return 'Upload → $folder';
  }

  @override
  String get transferQueued => 'waiting';

  @override
  String get transferPaused => 'Paused';

  @override
  String transferFailed(String reason) {
    return 'Failed: $reason';
  }

  @override
  String bytesOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String remaining(String time) {
    return '$time left';
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
  String get resumesWithRange => 'resumes (range)';

  @override
  String notificationTransfers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers running',
      one: '1 transfer running',
    );
    return '$_temp0';
  }

  @override
  String get errorExists => 'An item with this name already exists there.';

  @override
  String get errorLocalFile => 'Local file cannot be read or written.';

  @override
  String get storageUsed => 'Used on this device';

  @override
  String storageOffline(String size) {
    return 'Offline files $size';
  }

  @override
  String storageCache(String size) {
    return 'Cache $size';
  }

  @override
  String get offlineInfo =>
      'Everything here works without a connection. Changes on the NAS are checked on the next contact (mtime).';

  @override
  String get offlineEmpty =>
      'No offline files yet. “Keep available offline” in the file menu downloads files here.';

  @override
  String get offlineChanged => 'Changed on the NAS – update?';

  @override
  String get offlineRemove => 'Remove';

  @override
  String moreItems(int count) {
    return '+ $count more';
  }

  @override
  String get openFailed => 'No app found to open this file.';

  @override
  String get shareLinkTitle => 'Sharing link';

  @override
  String get shareValidUntil => 'Valid until';

  @override
  String get expiryDay1 => '1 day';

  @override
  String expiryDays(int count) {
    return '$count days';
  }

  @override
  String get expiryNever => 'Never';

  @override
  String get expiryNone => 'No expiry';

  @override
  String expiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get expiresToday => 'Expires today';

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days',
      one: 'Expires tomorrow',
    );
    return '$_temp0';
  }

  @override
  String expiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String get sharePassword => 'Password (optional)';

  @override
  String get generate => 'Generate';

  @override
  String get shareCreate => 'Create link';

  @override
  String get shareCreated => 'Link created';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get shareExternalHint =>
      'The link points to the external address. Manage all links in Settings › Sharing links.';

  @override
  String get shareNoExternal =>
      'No external address is set for this server: the link uses the address reported by DSM and may only work on the local network.';

  @override
  String get shareLinksTitle => 'Sharing links';

  @override
  String shareLinksCount(int active, int expired) {
    return '$active active · $expired expired';
  }

  @override
  String get shareLinksEmpty => 'No sharing links.';

  @override
  String get shareLinksFooter =>
      'Source: SYNO.FileStation.Sharing list. To change expiry or password, create the link again.';

  @override
  String get passwordBadge => 'Password';

  @override
  String get cleanUp => 'Clean up';

  @override
  String shareLinkDeleteConfirm(String name) {
    return 'Delete the share link for “$name”?';
  }

  @override
  String shareLinksCleanUpConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count expired links?',
      one: 'Delete 1 expired link?',
    );
    return '$_temp0';
  }

  @override
  String get shareLinkDeleteHint =>
      'The link stops working. The files on the NAS are kept.';

  @override
  String get trashTitle => 'Recycle bin';

  @override
  String get trashEmptyAction => 'Empty';

  @override
  String get trashChecking => 'Checking recycle bins …';

  @override
  String get trashInfo => 'Shows #recycle of the shared folder.';

  @override
  String get trashNone => 'No recycle bin visible.';

  @override
  String trashHidden(String shares) {
    return 'Missing: $shares – the recycle bin there is visible to admins only.';
  }

  @override
  String get trashIsEmpty => 'The recycle bin is empty.';

  @override
  String get trashFooter =>
      'Restore = move back to the original path (derived from the recycle bin path). Deleting permanently needs a second, red confirmation.';

  @override
  String trashFrom(String folder) {
    return 'from $folder';
  }

  @override
  String trashDeleted(String when) {
    return 'deleted $when';
  }

  @override
  String get restore => 'Restore';

  @override
  String get restoring => 'Restoring …';

  @override
  String restored(String path) {
    return 'Restored to $path';
  }

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String get deleteForeverTitle => 'Delete permanently?';

  @override
  String deleteForeverOne(String name) {
    return '“$name” will be removed from the recycle bin. Only a snapshot can undo this.';
  }

  @override
  String deleteForeverMany(int count) {
    return '$count items will be removed from the recycle bin. Only a snapshot can undo this.';
  }

  @override
  String get actionDeleteShort => 'Delete';

  @override
  String get noWritePermission =>
      'No write permission – the NAS only allows reading (and possibly deleting) here.';

  @override
  String get export => 'Export';

  @override
  String get viewerLoading => 'Loading …';

  @override
  String downloadProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String get openWith => 'Open with …';

  @override
  String get openWithFailed => 'No app found to open this file.';

  @override
  String get openWithHint => 'There is no in-app preview for this file type.';

  @override
  String get textTooLarge =>
      'The file is larger than 5 MB and is not shown here.';

  @override
  String get actionShare => 'Share';

  @override
  String get actionSaveToPhotos => 'To Photos';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get actionFavorite => 'Favorite';

  @override
  String imageOf(String index, String total) {
    return '$index of $total';
  }

  @override
  String get heicUnavailable => 'HEIC preview not available on the NAS';

  @override
  String get imageUnavailable => 'Image cannot be displayed';

  @override
  String get viewRendered => 'Rendered';

  @override
  String get viewRaw => 'Raw text';

  @override
  String get fontSize => 'Font size';

  @override
  String get docxBanner =>
      'Reading mode: simplified view. Page layout, headers and comments are not shown.';

  @override
  String get docxUnreadable =>
      'The document cannot be shown in reading mode. “Open with …” hands it to another app.';

  @override
  String get pdfPage => 'Page';

  @override
  String pdfOfTotal(String total) {
    return 'of $total';
  }

  @override
  String get pdfPrevious => 'Previous page';

  @override
  String get pdfNext => 'Next page';

  @override
  String get searchInDocument => 'Search in document';

  @override
  String get noMatches => 'No matches';

  @override
  String get previousMatch => 'Previous match';

  @override
  String get nextMatch => 'Next match';

  @override
  String resumeAt(String time) {
    return 'Resume at $time?';
  }

  @override
  String get restart => 'Start over';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get speed => 'Speed';

  @override
  String get rewind10 => 'Back 10 s';

  @override
  String get forward10 => 'Forward 10 s';

  @override
  String get play => 'Play';

  @override
  String volumePercent(String percent) {
    return 'Volume $percent%';
  }

  @override
  String brightnessPercent(String percent) {
    return 'Brightness $percent%';
  }

  @override
  String get fullscreen => 'Toggle full screen';

  @override
  String get videoUnavailable => 'Video cannot be played';

  @override
  String get audioChannelName => 'Playback';

  @override
  String get playFolder => 'Play folder';

  @override
  String get playingFromFolder => 'Playing from folder';

  @override
  String trackOf(int index, int count) {
    return 'Track $index of $count';
  }

  @override
  String get nowPlayingRow => 'now playing';

  @override
  String get queueTitle => 'Queue';

  @override
  String queueButton(int count) {
    return 'Queue ($count)';
  }

  @override
  String get queueClear => 'Clear';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String queueUpNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up next · $count tracks',
      one: 'Up next · 1 track',
      zero: 'Up next · no tracks',
    );
    return '$_temp0';
  }

  @override
  String queueHint(int played) {
    String _temp0 = intl.Intl.pluralLogic(
      played,
      locale: localeName,
      other:
          '$played tracks have already played. Swipe left to remove, drag the handle to move.',
      one: '1 track has already played. Swipe left to remove, drag the handle to move.',
      zero: 'Swipe left to remove, drag the handle to move.',
    );
    return '$_temp0';
  }

  @override
  String get queueRemove => 'Remove from queue';

  @override
  String get queueAdded => 'Added to queue';

  @override
  String get noAudioInFolder => 'No audio files in this folder.';

  @override
  String get nextTrack => 'Next track';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get collapse => 'Collapse';

  @override
  String get shuffleOn => 'Shuffle on';

  @override
  String get shuffleOff => 'Shuffle off';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatOne => 'Repeat track';

  @override
  String get repeatAll => 'Repeat folder';

  @override
  String get repeatSummaryOff => 'Folder · once';

  @override
  String get repeatSummaryOne => 'Track · repeat';

  @override
  String get repeatSummaryAll => 'Folder · repeat';

  @override
  String get shuffleSummary => 'Shuffled';

  @override
  String get speedTitle => 'Speed';

  @override
  String speedValue(String speed) {
    return '$speed×';
  }

  @override
  String get sleep => 'Sleep';

  @override
  String get sleepTitle => 'Sleep timer';

  @override
  String sleepMinutes(int minutes) {
    return 'Sleep $minutes min';
  }

  @override
  String get sleepEndOfTrackShort => 'Sleep: end of track';

  @override
  String sleepOption(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get sleepEndOfTrack => 'End of track';

  @override
  String get sleepOff => 'Off';

  @override
  String get resumeAction => 'Resume';

  @override
  String get errorWifiRequired =>
      'Streaming on Wi-Fi only – no Wi-Fi connection right now.';

  @override
  String get errorNotPlayable =>
      'Not playable: this format is not supported on this device.';

  @override
  String get audiobookMode => 'Audiobook mode';

  @override
  String get audiobookModeHint => 'Remembers track and position in this folder';

  @override
  String get settingsWifiOnly => 'Stream on Wi-Fi only';

  @override
  String get settingsWifiOnlyHint => 'No streaming over mobile data.';

  @override
  String get errorStreamFailed =>
      'Could not load the file – check the connection to the NAS.';

  @override
  String get playFolderShort => 'Play all';

  @override
  String get settingsSectionConnection => 'Connection';

  @override
  String get settingsServers => 'Manage servers';

  @override
  String settingsLinksActive(int count) {
    return '$count active';
  }

  @override
  String get settingsNeedsServer => 'Connect to a server first.';

  @override
  String get settingsSectionMedia => 'Media & storage';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsPlayback => 'Playback';

  @override
  String get settingsPlaybackHint => 'Resume, sleep timer';

  @override
  String get playbackInfo =>
      'The app remembers the position of every audio and video file and offers to resume next time. Sleep timer and speed are set in the player.';

  @override
  String playbackClearPositions(int count) {
    return 'Clear saved positions ($count)';
  }

  @override
  String get playbackPositionsCleared => 'Positions cleared.';

  @override
  String get settingsCacheLimit => 'Cache limit';

  @override
  String settingsCacheValue(String limit, String used) {
    return '$limit · $used used';
  }

  @override
  String get settingsCacheHint =>
      'Applies to streamed media, documents and thumbnails. Least recently used items are evicted first.';

  @override
  String get cacheClear => 'Clear cache';

  @override
  String get cacheCleared => 'Cache cleared.';

  @override
  String get settingsOfflineStorage => 'Offline storage';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsDesign => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String languageSystem(String language) {
    return '$language (system)';
  }

  @override
  String get languageSystemOption => 'System language';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsAbout => 'About & licenses';

  @override
  String get aboutLegalese =>
      'Free software (CC0), not a product of Synology Inc. The app sends no data to third parties. Video playback uses media_kit with libmpv and FFmpeg (LGPL 2.1 or later); source code and licenses at github.com/media-kit/media-kit.';

  @override
  String get settingsClearAll => 'Delete all local data';

  @override
  String get settingsClearAllHint => 'Cache, offline, tokens';

  @override
  String get settingsClearAllConfirm => 'Delete all local data?';

  @override
  String get settingsClearAllBody =>
      'This deletes the cache, offline files and transfers as well as sessions, device tokens, saved passwords and trusted certificates. Server profiles and settings stay; you will need to sign in again.';

  @override
  String get settingsClearAllAction => 'Delete everything';

  @override
  String get settingsCleared => 'Local data deleted.';

  @override
  String get autoUploadTitle => 'Auto upload';

  @override
  String get autoUploadHeroTitle => 'Back up photos & videos';

  @override
  String get autoUploadHeroSubtitle => 'New shots from the camera roll';

  @override
  String get autoUploadEnabled => 'New shots will be backed up from now on.';

  @override
  String get autoUploadTarget => 'Destination folder';

  @override
  String get autoUploadTargetNone => 'Not selected';

  @override
  String get autoUploadPickConfirm => 'Back up here';

  @override
  String get autoUploadNeedsSession =>
      'Connect to the server first to choose the destination folder.';

  @override
  String get autoUploadScheme => 'Folder scheme';

  @override
  String get schemeYearMonth => 'Year / month';

  @override
  String get schemeYear => 'Year';

  @override
  String get schemeFlat => 'No subfolders';

  @override
  String get autoUploadWifiOnly => 'Wi-Fi only';

  @override
  String get autoUploadWifiOnlyHint =>
      'Pauses on mobile data, even with an active VPN';

  @override
  String get autoUploadVideos => 'Include videos';

  @override
  String get autoUploadVideosHint => 'Can use a lot of data';

  @override
  String get autoUploadCharging => 'Only while charging';

  @override
  String get autoUploadChargingHint => 'Saves battery with large backlogs';

  @override
  String get autoUploadPermissionDenied =>
      'Without access to all photos, auto upload cannot back up anything. You can allow access in the system settings.';

  @override
  String get openSystemSettings => 'Open settings';

  @override
  String get autoUploadStatus => 'Status';

  @override
  String autoUploadLastRun(String when, int files, int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return 'Last run $when · $_temp0 · $failed errors';
  }

  @override
  String get autoUploadNeverRun => 'Nothing backed up yet';

  @override
  String get autoUploadRunning => 'Running …';

  @override
  String autoUploadLastCheck(String when) {
    return 'Last checked $when';
  }

  @override
  String autoUploadTotal(String files, String size) {
    return 'Backed up in total: $files files · $size';
  }

  @override
  String get autoUploadRunNow => 'Run now';

  @override
  String get autoUploadLog => 'Log';

  @override
  String get autoUploadLogEmpty => 'No entries yet.';

  @override
  String autoUploadRunSummary(int files, int failed, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      files,
      locale: localeName,
      other: '$files files',
      one: '1 file',
    );
    return '$_temp0 · $failed errors · $size';
  }

  @override
  String autoUploadWaitingWifi(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files wait',
      one: '1 file waits',
    );
    return '$_temp0 for Wi-Fi';
  }

  @override
  String autoUploadWaitingCharging(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files wait',
      one: '1 file waits',
    );
    return '$_temp0 for charging';
  }

  @override
  String autoUploadNoteUnreachable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files wait',
      one: '1 file waits',
    );
    return 'NAS not reachable – $_temp0';
  }

  @override
  String autoUploadNoteOtherServer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files wait',
      one: '1 file waits',
    );
    return 'Another server is signed in – $_temp0';
  }

  @override
  String get autoUploadNoteSession =>
      'Session expired – please sign in again in the app';

  @override
  String get autoUploadNoteWrite =>
      'No write permission in the destination folder – choose another folder or adjust the permissions in DSM';

  @override
  String get autoUploadNoteTarget => 'Destination folder not found';

  @override
  String get autoUploadNotePermission =>
      'No access to photos – allow it in the system settings';

  @override
  String get autoUploadNoteError => 'Error in the last run';

  @override
  String get autoUploadIosHint =>
      'On iPhone, background uploads only run when the system allows it; anything missed is caught up when you open the app.';

  @override
  String get autoUploadNotification => 'Auto upload';
}
