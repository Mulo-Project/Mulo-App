// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Music';

  @override
  String get navSearch => 'Search';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionPause => 'Pause';

  @override
  String get playerFloatExpand => 'Back to mini player';

  @override
  String get actionNext => 'Next';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionBack => 'Back';

  @override
  String get actionMore => 'More';

  @override
  String get actionDownload => 'Download';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionPlayAll => 'Play all';

  @override
  String get actionShuffle => 'Shuffle';

  @override
  String get unitSongs => 'songs';

  @override
  String songCount(int count) {
    return '$count songs';
  }

  @override
  String get searchSubtitle => 'Find & download';

  @override
  String get searchHint => 'YouTube URL or keywords';

  @override
  String get searchEmptyTitle => 'What do you want to save?';

  @override
  String get searchEmptyBody =>
      'Paste a link or type keywords.\nPick the site to search with the icon on the left.';

  @override
  String get searchEngineNeededTitle => 'Download engine required';

  @override
  String get searchEngineNeededBody =>
      'yt-dlp isn\'t installed, so search isn\'t available.\nInstall it to search and download right away.';

  @override
  String get searchEngineInstallFailed =>
      'Couldn\'t install it. Check your connection and try again.';

  @override
  String get searchNotReadyTitle => 'No engine available';

  @override
  String get searchNotReadyBody =>
      'This build has no server address and yt-dlp is not installed on this device, so search is unavailable.\nConnect a server or install yt-dlp.';

  @override
  String get searchErrorTitle => 'Could not load';

  @override
  String get searchErrorBody => 'Please try again in a moment.';

  @override
  String get searchNetworkBody =>
      'Could not reach the server. Check your internet connection.';

  @override
  String get stateNetworkTitle => 'Network connection needed';

  @override
  String get stateNetworkBody => 'Check your connection and try again.';

  @override
  String get stateTimeoutTitle => 'It is taking too long to respond';

  @override
  String get stateTimeoutBody => 'Please try again in a moment.';

  @override
  String get stateSignInTitle => 'Sign-in needed';

  @override
  String get stateSignInBody => 'Sign in to use this.';

  @override
  String get searchAuthBody => 'The server requires a sign-in.';

  @override
  String get searchNotFoundBody => 'This address cannot be downloaded.';

  @override
  String get searchNoResultsTitle => 'No results';

  @override
  String get searchNoResultsBody => 'Try a different search.';

  @override
  String get searchLoadMore => 'Load more';

  @override
  String get searchResultsTitle => 'Results';

  @override
  String get searchUrlCardLabel => 'Found from URL';

  @override
  String get searchPlaylistLabel => 'Playlist';

  @override
  String get searchSelectAll => 'Select all';

  @override
  String searchDownloadSelected(int count) {
    return 'Download $count';
  }

  @override
  String get alreadyDownloaded => 'Already saved';

  @override
  String get downloadsActive => 'Active';

  @override
  String downloadsWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get downloadsPauseAll => 'Pause all';

  @override
  String get downloadsResumeAll => 'Resume all';

  @override
  String get downloadsHideCurrent => 'Hide current song';

  @override
  String get downloadsShowCurrent => 'Show current song';

  @override
  String get downloadsClearDone => 'Clear finished';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusDone => 'Done';

  @override
  String get downloadsEmpty => 'Nothing downloading.';

  @override
  String get librarySubtitle => 'My music';

  @override
  String get librarySongs => 'Songs';

  @override
  String get libraryArtists => 'Artists';

  @override
  String get libraryAlbums => 'Albums';

  @override
  String get librarySearchHint => 'Search library';

  @override
  String get libraryGenres => 'Genres';

  @override
  String get unknownGenre => 'Unknown genre';

  @override
  String get genreNotFound => 'Genre not found';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get sortName => 'Name';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortCount => 'Song count';

  @override
  String get libraryImport => 'Import device music';

  @override
  String get libraryNoMatch => 'No matches.';

  @override
  String get playlistsSubtitle => 'Collections';

  @override
  String get playlistsNew => 'New playlist';

  @override
  String get playlistsImport => 'Import YouTube playlist';

  @override
  String get settingsSubtitle => 'Preferences';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsConnection => 'Connection';

  @override
  String get settingsDisconnected => 'Disconnected';

  @override
  String get settingsServerConfigured => 'Server address set';

  @override
  String get settingsMode => 'Download mode';

  @override
  String get settingsModeServer => 'Server';

  @override
  String get settingsModeLocal => 'Local';

  @override
  String get settingsModeLiteNote =>
      'The lite build supports server mode only.';

  @override
  String get settingsDownload => 'Downloads';

  @override
  String get settingsSavePath => 'Save location';

  @override
  String get settingsSavePathDesc => 'App default folder';

  @override
  String get settingsLoadedFolders => 'Music folders';

  @override
  String settingsLoadedFoldersCount(int count) {
    return '$count folders';
  }

  @override
  String get loadedFoldersHint =>
      'Music in these folders is loaded into your library, including subfolders.';

  @override
  String loadedFoldersTrackCount(int count) {
    return '$count songs';
  }

  @override
  String get loadedFoldersDefault => 'Default save location';

  @override
  String get loadedFoldersAdd => 'Add folder';

  @override
  String get loadedFoldersRemove => 'Remove folder';

  @override
  String get loadedFoldersRemoveTitle => 'Remove this folder?';

  @override
  String loadedFoldersRemoveBody(String path, int count) {
    return '$path\n$count songs from this folder will leave your library. The music files are not deleted.';
  }

  @override
  String loadedFoldersRemoveBodyEmpty(String path) {
    return '$path\nThe music files are not deleted.';
  }

  @override
  String get loadedFoldersScanning => 'Finding songs in the folder';

  @override
  String get loadedFoldersRemoving =>
      'Removing the folder and tidying your library';

  @override
  String get loadedFoldersReading => 'Reading song info';

  @override
  String get loadedFoldersCovers => 'Getting song images';

  @override
  String loadedFoldersPlaylistTitle(int count) {
    return 'Add the $count loaded songs to playlists?';
  }

  @override
  String get loadedFoldersPlaylistSkip => 'Skip';

  @override
  String get loadedFoldersPlaylistAdd => 'Add';

  @override
  String loadedFoldersAddedToPlaylists(int songs, int count) {
    return 'Added $songs songs to $count playlists';
  }

  @override
  String get settingsFormat => 'Default format';

  @override
  String get settingsEngine => 'Download engine';

  @override
  String settingsEngineVersion(String current, String latest) {
    return 'Current $current · Latest $latest';
  }

  @override
  String get settingsEngineUpdate => 'Update';

  @override
  String get settingsEngineInstall => 'Install';

  @override
  String get settingsEngineNotInstalled =>
      'yt-dlp is missing. Install it to search and download.';

  @override
  String get settingsEngineRemove => 'Remove';

  @override
  String get settingsEngineRemoveTitle => 'Remove the download engine?';

  @override
  String get settingsEngineRemoveBody =>
      'Deletes the yt-dlp file the app downloaded. You will need to install it again to search and download. A yt-dlp installed separately on this device is not removed.';

  @override
  String get settingsEngineInstalling => 'Downloading…';

  @override
  String get settingsEngineReverting => 'Reverting…';

  @override
  String get settingsEngineRevertTitle => 'Remove the updated yt-dlp?';

  @override
  String get settingsEngineRevertBody =>
      'Deletes the yt-dlp you updated and returns to the version that came with the app. Use this if search or downloads stopped working after an update. You can update again later.';

  @override
  String get settingsEngineRevertFailed =>
      'Could not remove it. Please try again in a moment.';

  @override
  String get settingsEngineBundled => 'Built-in yt-dlp';

  @override
  String get settingsEngineFailed =>
      'Could not install. Check your internet connection.';

  @override
  String settingsEngineInstalled(String version) {
    return 'yt-dlp $version';
  }

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsChangePinDesc =>
      'Confirm your current PIN (or fingerprint/face), then set a new one.';

  @override
  String get settingsAppLockDesc =>
      'Asks for a PIN (4-6 digits) when you open the app.';

  @override
  String get settingsBiometric => 'Unlock with fingerprint or face';

  @override
  String get settingsBiometricDesc =>
      'Use your device\'s biometrics instead of the PIN.';

  @override
  String get biometricReason => 'Unlock Mulo';

  @override
  String get pinCreateTitle => 'Set a PIN';

  @override
  String get pinCreateHint => 'Enter 4-6 digits.';

  @override
  String get pinConfirmTitle => 'Confirm PIN';

  @override
  String get pinConfirmHint => 'Enter the same PIN again.';

  @override
  String get pinMismatch => 'The PINs don\'t match. Please start over.';

  @override
  String get pinCurrentTitle => 'Current PIN';

  @override
  String get pinCurrentHint => 'Enter your current PIN to turn off the lock.';

  @override
  String get pinCurrentHintChange => 'Enter your current PIN to change it.';

  @override
  String get pinCurrentHintBiometric =>
      'Enter your current PIN or confirm with fingerprint or face.';

  @override
  String get pinWrong => 'Wrong PIN.';

  @override
  String pinCooldown(int seconds) {
    return 'Try again in ${seconds}s.';
  }

  @override
  String get pinSubmit => 'OK';

  @override
  String get pinBackspace => 'Delete';

  @override
  String get pinUseBiometric => 'Unlock with biometrics';

  @override
  String get lockTitle => 'Locked';

  @override
  String get lockHint => 'Enter your PIN.';

  @override
  String get settingsBackgroundDownload => 'Background downloads';

  @override
  String get settingsBackgroundDownloadDesc =>
      'Keeps downloading when the app is in the background or closed. A notification stays up while downloading.';

  @override
  String get settingsHideNotification => 'Hide song info in notification';

  @override
  String get settingsHideNotificationDesc =>
      'Shows only \"Playing music\" on notifications and lock screen, and hides song info in download notifications too.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeColorFollowing =>
      'Following the playing song\'s colors while Follow song mood is on.';

  @override
  String get settingsFollowMood => 'Follow song mood';

  @override
  String get settingsFollowMoodDesc =>
      'Accent colors follow the current song\'s cover.';

  @override
  String get settingsThemeColor => 'Theme color';

  @override
  String get settingsThemePreview => 'Theme preview';

  @override
  String get settingsThemePreviewDesc =>
      'Browse the real screens with a theme, then apply it.';

  @override
  String get settingsPlayback => 'Playback options';

  @override
  String get settingsMixWithOthers => 'Play with other apps';

  @override
  String get settingsMixWithOthersDesc =>
      'Keep playing when another app makes sound. Audio may overlap and get loud.';

  @override
  String get settingsPauseOnDisconnect => 'Pause when device disconnects';

  @override
  String get settingsPauseOnDisconnectDesc =>
      'Stop playback when earphones are unplugged or Bluetooth disconnects.';

  @override
  String get settingsResumeOnConnect => 'Resume when device connects';

  @override
  String get settingsResumeOnConnectDesc =>
      'If playback stopped because of a disconnect, resume when a device reconnects within 10 minutes.';

  @override
  String get settingsResumeWithoutNotification =>
      'Play from Bluetooth without a notification';

  @override
  String get settingsResumeWithoutNotificationDesc =>
      'Even after you dismiss the notification or playback ends, the play button on a Bluetooth device resumes the last song.';

  @override
  String get playerStyleTitle => 'Player theme';

  @override
  String get playerSpeedTitle => 'Playback speed';

  @override
  String playerSpeedValue(String speed) {
    return '${speed}x';
  }

  @override
  String get playerSpeedNormal => 'Normal';

  @override
  String get playerStyleSquare => 'Square';

  @override
  String get playerStyleFullBleed => 'Full image';

  @override
  String get playerStyleArc => 'Arc';

  @override
  String get playerSleepTimer => 'Sleep timer';

  @override
  String get playerSleepTimerOff => 'Turn off timer';

  @override
  String playerSleepTimerMinutes(int minutes) {
    return 'Stop in $minutes min';
  }

  @override
  String playerSleepTimerSet(int minutes) {
    return 'Playback will stop in $minutes min';
  }

  @override
  String get playerSleepTimerUnitHour => 'h';

  @override
  String get playerSleepTimerUnitMinute => 'm';

  @override
  String get playerSleepTimerStart => 'Start';

  @override
  String get playerSleepTimerCleared => 'Sleep timer is off';

  @override
  String get playerEqualizer => 'Equalizer';

  @override
  String get playerLyrics => 'Lyrics';

  @override
  String get playerRewind10 => 'Back 10 seconds';

  @override
  String get playerForward10 => 'Forward 10 seconds';

  @override
  String get themePreviewHint => 'Switch tabs to check how it looks';

  @override
  String get themePreviewApply => 'Apply';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsPurgeHidden => 'Clear hidden song records';

  @override
  String settingsPurgeHiddenDesc(int count) {
    return 'Records of $count hidden songs from removed folders are kept';
  }

  @override
  String get settingsPurgeHiddenNone => 'Nothing to clear';

  @override
  String get settingsPurgeHiddenTitle => 'Clear hidden song records?';

  @override
  String settingsPurgeHiddenBody(int count) {
    return 'Play counts, likes, playlist entries, covers and the lyrics copies saved in the app for $count hidden songs will be deleted. The music files and their tags (including lyrics) are not touched.';
  }

  @override
  String settingsPurgeHiddenDone(int count) {
    return 'Cleared records of $count songs';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerQueue => 'Up next';

  @override
  String get outputSpeaker => 'Phone speaker';

  @override
  String get outputWired => 'Wired headphones';

  @override
  String get outputBluetooth => 'Bluetooth';

  @override
  String get outputUsb => 'USB audio';

  @override
  String get outputOther => 'External output';

  @override
  String get shuffleOn => 'Shuffle on';

  @override
  String get shuffleOff => 'Shuffle off';

  @override
  String get queueClear => 'Clear queue';

  @override
  String get queueSelect => 'Select songs';

  @override
  String get queueCleared => 'Queue cleared';

  @override
  String get queueClearTitle => 'Clear the queue?';

  @override
  String get queueClearBody =>
      'The current song stops and every song leaves the queue. Your library is not affected.';

  @override
  String get queueClearConfirm => 'Clear';

  @override
  String get queueReorderHint => 'Press and hold, then drag to reorder';

  @override
  String get playerLoop => 'A-B repeat';

  @override
  String get playerLoopSetStart => 'A-B repeat: set the start point';

  @override
  String get playerLoopSetEnd => 'A-B repeat: set the end point';

  @override
  String get playerLoopClear => 'Turn off A-B repeat';

  @override
  String get playerRepeat => 'Repeat';

  @override
  String playerFrom(String source) {
    return 'Playing from $source';
  }

  @override
  String get themeViolet => 'Violet';

  @override
  String get themeCoral => 'Coral';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeGold => 'Gold';

  @override
  String get themeIce => 'Ice';

  @override
  String get coverPick => 'Choose image';

  @override
  String get coverReset => 'Use default';

  @override
  String get coverSourceTitle => 'Where from?';

  @override
  String get coverSourceDevice => 'From this device';

  @override
  String get coverSourceWeb => 'From the web';

  @override
  String get coverAdjust => 'Adjust position';

  @override
  String get coverWebBrowserHelp =>
      'Tap an image to go straight to the editor.';

  @override
  String get coverWebHint => 'Image URL or search words';

  @override
  String get coverWebHelp =>
      'Paste an image URL (https://…) or search and pick one.';

  @override
  String get coverWebUseUrl => 'Use the image at this URL';

  @override
  String get coverWebEmpty => 'No images found';

  @override
  String get coverWebFailed => 'Couldn\'t search. Try again in a moment';

  @override
  String get coverEditTitle => 'Image';

  @override
  String get coverEditHint =>
      'Inside the frame is the real cover. Dimmed parts are cropped; empty parts are black. Drag to move, pinch to zoom and rotate';

  @override
  String get coverEditZoomIn => 'Zoom in';

  @override
  String get coverEditZoomOut => 'Zoom out';

  @override
  String get coverEditReset => 'Reset';

  @override
  String get coverEditResetPosition => 'Reset position';

  @override
  String get coverEditResetTitle => 'Reset position and size?';

  @override
  String get coverEditResetBody =>
      'Zoom, position and rotation go back to the start.';

  @override
  String get coverEditResetConfirm => 'Reset';

  @override
  String get coverChange => 'Change image';

  @override
  String get coverRemove => 'Remove image';

  @override
  String get coverRemoveTitle => 'Remove the image?';

  @override
  String get coverRemoveBody =>
      'The image you picked is removed. You can pick one again later.';

  @override
  String get coverRevertTitle => 'Go back to the default image?';

  @override
  String get coverRevertBody =>
      'The image you picked is removed and the default image comes back.';

  @override
  String get coverEditApply => 'Apply';

  @override
  String get coverEditEmpty => 'Load an image above';

  @override
  String get coverEditRotation => 'Rotation';

  @override
  String get coverEditRotateLeft => 'Left 90°';

  @override
  String get coverEditRotateRight => 'Right 90°';

  @override
  String get coverEditLoadFailed => 'Couldn\'t load the image';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLight => 'Light';

  @override
  String get libraryEmptyTitle => 'No music yet';

  @override
  String get libraryEmptyBody =>
      'Import music from this device\nor download from Search.';

  @override
  String get importing => 'Importing…';

  @override
  String importAdded(int count) {
    return 'Imported $count songs';
  }

  @override
  String get importNothingNew => 'No new songs';

  @override
  String get importDenied => 'Music access is needed. Allow it in Settings.';

  @override
  String get importFailed => 'Couldn\'t import music';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String librarySources(int device, int downloaded) {
    return '$device from device · $downloaded downloaded';
  }

  @override
  String get navHome => 'Home';

  @override
  String get homeSubtitle => 'Today';

  @override
  String get homePeriodWeek => 'This week';

  @override
  String get homePeriodMonth => 'This month';

  @override
  String get homePeriodAll => 'All time';

  @override
  String get homeToday => 'Listened today';

  @override
  String homeTodayMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String homeTodayHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String homeTodayPlays(int count) {
    return '$count plays today';
  }

  @override
  String get homeTodayNone => 'Nothing played yet today';

  @override
  String get homeStats => 'Listening';

  @override
  String get homeStatPlays => 'plays';

  @override
  String get homeStatTracks => 'songs';

  @override
  String get homeTopArtist => 'Top artist';

  @override
  String get homeTopTracks => 'Most played';

  @override
  String get homeRecommendations => 'Recommended playlists';

  @override
  String get homeRecent => 'Recently played';

  @override
  String get homeNoPlays => 'No plays yet. Play something from your library.';

  @override
  String get homeNoRecommendations => 'Add more songs to get recommendations.';

  @override
  String get homeEmptyLibraryTitle => 'Your library is empty';

  @override
  String get homeEmptyLibraryBody =>
      'Import or download music to see\nyour top songs and recommendations here.';

  @override
  String get homeGoLibrary => 'Go to library';

  @override
  String get homeTopTracksGo => 'See TOP 100';

  @override
  String get homeRecentList => 'Recently played';

  @override
  String homeAllSince(String date) {
    return 'Since $date';
  }

  @override
  String get homeRecRediscover => 'Play it again';

  @override
  String get homeChipTracks => 'Songs';

  @override
  String get homeChipArtists => 'Artists';

  @override
  String get homeChipGenres => 'Genres';

  @override
  String get homeMonthPrev => 'Previous month';

  @override
  String get homeMonthNext => 'Next month';

  @override
  String get homeHistory => 'Play history';

  @override
  String get homeMetricPlays => 'Plays';

  @override
  String get homeMetricTime => 'Time';

  @override
  String get homePickMonth => 'Pick a month';

  @override
  String homeMonthLabel(int year, int month) {
    return '$month/$year';
  }

  @override
  String homeYearLabel(int year) {
    return '$year';
  }

  @override
  String homeMonthShort(int month) {
    return '$month';
  }

  @override
  String get homeAllDays => 'Days listened';

  @override
  String homeAllDaysValue(int count) {
    return '$count days';
  }

  @override
  String get homeAllTime => 'Total listening time';

  @override
  String get homeAllPlays => 'Total plays';

  @override
  String get homeAllTracks => 'Songs played';

  @override
  String get homeChartNone => 'Nothing played in this period.';

  @override
  String get homeTopAlbum => 'Top album';

  @override
  String get homeTopTracksMore => 'See all';

  @override
  String get homeTopTracksTitle => 'Most played TOP 100';

  @override
  String homeRecArtist(String artist) {
    return '$artist mix';
  }

  @override
  String homeRecGenre(String genre) {
    return '$genre picks';
  }

  @override
  String get homeRecUnheard => 'Not heard yet';

  @override
  String get homeRecNewest => 'Recently added';

  @override
  String playCount(int count) {
    return '$count plays';
  }

  @override
  String searchHintSite(String site) {
    return '$site URL or keywords';
  }

  @override
  String get sourceSoundcloud => 'SoundCloud';

  @override
  String get searchSubmitTooltip => 'Search';

  @override
  String get searchPasteLink => 'Paste link';

  @override
  String get searchPasteEmpty => 'No link on the clipboard';

  @override
  String get searchSourceTooltip => 'Search source';

  @override
  String get sourceYoutube => 'YouTube';

  @override
  String get searchHitMenuDetail => 'View details';

  @override
  String get searchPreview => 'Preview';

  @override
  String get searchPreviewStop => 'Stop preview';

  @override
  String get searchPreviewPause => 'Pause preview';

  @override
  String get searchPreviewResume => 'Resume preview';

  @override
  String get searchPreviewLoading => 'Preparing preview';

  @override
  String get searchPreviewFailed => 'Couldn\'t start the preview.';

  @override
  String get searchPreviewUnavailable =>
      'Preview isn\'t available on this device.';

  @override
  String get mediaDetailTitle => 'Details';

  @override
  String get mediaDetailWatchYoutube => 'Watch on YouTube';

  @override
  String get mediaDetailOpenOriginal => 'Open original page';

  @override
  String get mediaDetailListenOriginal => 'Listen on the original site';

  @override
  String get mediaDetailListenSoundcloud => 'Listen on SoundCloud';

  @override
  String get mediaDetailOpenArtist => 'View artist';

  @override
  String get mediaDetailPlays => 'Plays';

  @override
  String get mediaDetailGenre => 'Genre';

  @override
  String mediaDetailFollowers(String count) {
    return '$count followers';
  }

  @override
  String get mediaDetailChannel => 'Channel';

  @override
  String get mediaDetailSite => 'Source';

  @override
  String get mediaDetailUploader => 'Uploaded by';

  @override
  String get mediaDetailOpenChannel => 'View channel';

  @override
  String get mediaDetailDuration => 'Length';

  @override
  String get mediaDetailViews => 'Views';

  @override
  String get mediaDetailUploaded => 'Uploaded';

  @override
  String get mediaDetailCategory => 'Category';

  @override
  String get mediaDetailDescription => 'Description';

  @override
  String get mediaDetailSectionPreview => 'Preview';

  @override
  String get mediaDetailSectionInfo => 'Info';

  @override
  String get mediaDetailMore => 'Show more';

  @override
  String get mediaDetailLikes => 'Likes';

  @override
  String mediaDetailSubscribers(String count) {
    return '$count subscribers';
  }

  @override
  String get mediaDetailCollaborators => 'Collaborators';

  @override
  String get mediaDetailPlayInApp => 'Play in app';

  @override
  String get mediaDetailEmbedBlocked =>
      'This video can\'t be played in the app. Use the button below to open it on YouTube.';

  @override
  String get mediaDetailLess => 'Show less';

  @override
  String get mediaDetailOpenFailed => 'No app can open this link.';

  @override
  String mediaDetailViewCount(String count) {
    return '$count views';
  }

  @override
  String get searchSortTooltip => 'Sort';

  @override
  String get searchSortRelevance => 'Relevance';

  @override
  String get searchSortPopular => 'Most viewed';

  @override
  String get searchSortNewest => 'Newest';

  @override
  String get searchSortDuration => 'Length';

  @override
  String get searchSortTitle => 'Title';

  @override
  String videoCategory(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'FilmAnimation': 'Film & Animation',
      'Autos': 'Autos & Vehicles',
      'Music': 'Music',
      'Pets': 'Pets & Animals',
      'Sports': 'Sports',
      'Travel': 'Travel & Events',
      'Gaming': 'Gaming',
      'People': 'People & Blogs',
      'Comedy': 'Comedy',
      'Entertainment': 'Entertainment',
      'News': 'News & Politics',
      'Howto': 'Howto & Style',
      'Education': 'Education',
      'Science': 'Science & Technology',
      'Nonprofits': 'Nonprofits & Activism',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String downloadsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '1 left',
    );
    return '$_temp0';
  }

  @override
  String get downloadsExpand => 'Show queue';

  @override
  String get downloadsCollapse => 'Hide queue';

  @override
  String get downloadDialogTitle => 'Download details';

  @override
  String get downloadFieldCover => 'Cover';

  @override
  String get downloadCoverChange => 'Change';

  @override
  String get downloadCoverDefault => 'Use default';

  @override
  String get downloadLyricsEditHint =>
      'Load from a file or the web, or write it yourself. No subtitles needed.';

  @override
  String get downloadLyricsOverwriteTitle => 'You set your own lyrics';

  @override
  String get downloadLyricsOverwriteBody =>
      'Using the video subtitles will remove the lyrics you set. Continue?';

  @override
  String get downloadLyricsOverwriteConfirm => 'Use subtitles';

  @override
  String downloadLyricsCustom(int lines) {
    return 'Using your lyrics · $lines lines';
  }

  @override
  String get downloadImportLyrics => 'Import subtitles as lyrics';

  @override
  String get downloadImportLyricsHint =>
      'After downloading, refine them in the lyrics sync screen.';

  @override
  String get downloadSubtitleChecking => 'Checking for subtitles.';

  @override
  String get downloadSubtitleNone => 'This video has no subtitles.';

  @override
  String get downloadSubtitleUnknown =>
      'Couldn\'t check for subtitles. If on, we\'ll try again after downloading.';

  @override
  String get downloadSubtitleLanguage => 'Subtitle language';

  @override
  String get downloadSubtitleAuto => 'Choose automatically';

  @override
  String get downloadSubtitleAutoHint =>
      'Korean, then English, then the first one.';

  @override
  String get downloadLyricsPreviewLoading => 'Loading…';

  @override
  String get downloadLyricsPreviewFailed => 'Couldn\'t load the subtitles.';

  @override
  String get downloadSubtitleEditHint =>
      'You can edit the text, but not the timing. Sync it on the player after downloading.';

  @override
  String get downloadSubtitleUseEdited => 'Use this subtitle';

  @override
  String get downloadSubtitleApplied => 'applied';

  @override
  String get downloadLyricsRetry => 'Try again';

  @override
  String get downloadSubtitleUse => 'Use this subtitle';

  @override
  String get downloadSubtitleInUse => 'Currently selected';

  @override
  String get downloadLyricsSkipSounds => 'Skip sound-effect lines';

  @override
  String get downloadLyricsSkipSoundsHint =>
      'Lines like [Music], (applause) or ♪ aren\'t imported.';

  @override
  String get downloadSubtitleColLanguage => 'Language';

  @override
  String get downloadSubtitleColKind => 'Type';

  @override
  String get downloadSubtitleKindAuto => 'Auto-generated';

  @override
  String get downloadSubtitleKindManual => 'Uploaded by creator';

  @override
  String downloadSubtitleFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subtitle tracks found.',
      one: '1 subtitle track found.',
    );
    return '$_temp0';
  }

  @override
  String get downloadSectionInfo => 'Details';

  @override
  String get downloadSectionSave => 'Save to';

  @override
  String get downloadSectionLyrics => 'Lyrics';

  @override
  String get downloadCancelTitle => 'Cancel download';

  @override
  String downloadCancelBody(String title) {
    return 'Cancel downloading \"$title\"? What has been downloaded so far will be discarded.';
  }

  @override
  String get downloadCancelKeep => 'Keep downloading';

  @override
  String get downloadCancelConfirm => 'Cancel download';

  @override
  String get downloadsCancelAll => 'Cancel all';

  @override
  String get downloadsCancelAllTitle => 'Cancel all downloads';

  @override
  String downloadsCancelAllBody(int count) {
    return 'Cancel all $count downloads in progress or waiting? Partly downloaded files will be discarded.';
  }

  @override
  String downloadsOverall(int done, int total) {
    return '$done of $total';
  }

  @override
  String playlistDownloadsTitle(int count) {
    return 'Downloading $count';
  }

  @override
  String get downloadFieldTitle => 'Title';

  @override
  String get downloadFieldArtist => 'Artist';

  @override
  String get downloadFieldAlbum => 'Album';

  @override
  String get downloadFieldGenre => 'Genre';

  @override
  String get downloadFieldSavePath => 'Save location';

  @override
  String get downloadGenreExisting => 'Pick from existing genres';

  @override
  String get saveFolderTitle => 'Choose save location';

  @override
  String get saveFolderEmpty => 'No loaded folders yet. Pick one yourself.';

  @override
  String get saveFolderPickOther => 'Pick another';

  @override
  String get downloadPickFolder => 'Choose folder';

  @override
  String get downloadPlaylistsLabel => 'Add to playlists';

  @override
  String get downloadPlaylistsEmpty => 'No playlists yet. Create one below.';

  @override
  String get downloadNewPlaylist => 'New playlist';

  @override
  String get downloadNewPlaylistHint => 'Type a name, then +';

  @override
  String get downloadQueued => 'Added to the queue';

  @override
  String get downloadAlreadyDownloaded => 'This song is already downloaded';

  @override
  String get downloadStateDownloading => 'Downloading';

  @override
  String get downloadStateQueued => 'Queued';

  @override
  String get downloadStateDone => 'Downloaded';

  @override
  String get downloadAlreadyInQueue =>
      'This song is already downloading or queued';

  @override
  String get homeTopGenre => 'Top genre';

  @override
  String get playlistsEmpty => 'No playlists yet. Tap + above to make one.';

  @override
  String get playlistNewTitle => 'New playlist';

  @override
  String get playlistNewHint => 'Playlist name';

  @override
  String get playlistCreate => 'Create';

  @override
  String get decorateTitle => 'Customize';

  @override
  String get decorateImage => 'Image';

  @override
  String get decorateColor => 'Color';

  @override
  String get decorateAlbumTooltip => 'Customize album';

  @override
  String get decorateArtistTooltip => 'Customize artist';

  @override
  String get playlistMenuDecorate => 'Customize';

  @override
  String get trackMenuDecorate => 'Customize';

  @override
  String get albumRenameTooltip => 'Rename album';

  @override
  String get albumRenameTitle => 'Rename album';

  @override
  String get albumRenameHint => 'Album name';

  @override
  String get albumRenameSave => 'Rename';

  @override
  String get albumRenameDone => 'Album renamed';

  @override
  String get artistRenameTooltip => 'Rename artist';

  @override
  String get artistRenameTitle => 'Rename artist';

  @override
  String get artistRenameHint => 'Artist name';

  @override
  String get genreRenameTooltip => 'Rename genre';

  @override
  String get genreRenameTitle => 'Rename genre';

  @override
  String get genreRenameHint => 'Genre name';

  @override
  String get renameProgressTitle => 'Updating songs';

  @override
  String renameProgressCount(int done, int total) {
    return '$done/$total';
  }

  @override
  String get artistNotFound => 'Artist not found';

  @override
  String get playlistMenuColor => 'Card color';

  @override
  String get playlistColorAuto => 'Auto';

  @override
  String get colorCustom => 'Pick a custom hue';

  @override
  String colorOption(int n) {
    return 'Color $n';
  }

  @override
  String get playlistSummaryEmpty => 'Empty';

  @override
  String downloadColorSaveForGenre(String genre) {
    return 'Save as the default color for \'$genre\'';
  }

  @override
  String get downloadPlaylistsNone => 'None';

  @override
  String downloadPlaylistsSelected(int count) {
    return '$count selected';
  }

  @override
  String get downloadPlaylistsPickTitle => 'Choose playlists';

  @override
  String get downloadPlaylistsDone => 'Done';

  @override
  String get trackMenuTitle => 'Song menu';

  @override
  String get trackMenuPlayNext => 'Play next';

  @override
  String get trackMenuAddToQueue => 'Add to queue';

  @override
  String get trackMenuAddToPlaylist => 'Add to playlist';

  @override
  String get trackMenuEditInfo => 'Edit info';

  @override
  String get trackMenuDelete => 'Delete';

  @override
  String get trackMenuRemoveFromQueue => 'Remove from queue';

  @override
  String get trackRemovedFromQueue => 'Removed from the queue.';

  @override
  String get trackMenuRemoveFromPlaylist => 'Remove from playlist';

  @override
  String get trackMenuDeleteFile => 'Delete file';

  @override
  String get trackRemovedFromPlaylist => 'Removed from the playlist';

  @override
  String get trackDeleteFailed =>
      'Could not delete the file. Check permissions and try again.';

  @override
  String get trackMenuPlayNextDone => 'Playing next';

  @override
  String get trackMenuAddedToQueue => 'Added to the queue';

  @override
  String get trackMenuNoPlaylists =>
      'No playlists yet. Create one in the Playlists tab first.';

  @override
  String trackMenuAddedToPlaylists(int count) {
    return 'Added to $count playlist(s)';
  }

  @override
  String get trackEditTitle => 'Edit song info';

  @override
  String get trackEditName => 'Title';

  @override
  String get trackEditArtist => 'Artist';

  @override
  String get trackEditAlbum => 'Album';

  @override
  String get trackEditGenre => 'Genre';

  @override
  String get trackEditSave => 'Save';

  @override
  String get trackEditSaved => 'Song info updated';

  @override
  String get trackEditTagFailed =>
      'Could not write the info to the music file, so nothing was changed. Try again later.';

  @override
  String get trackDeleteTitle => 'Delete song';

  @override
  String trackDeleteBody(String title) {
    return 'Delete the music file \"$title\" from your device? It will also leave your library and playlists. This cannot be undone.';
  }

  @override
  String get trackDeleteConfirm => 'Delete';

  @override
  String get trackDeleted => 'Deleted';

  @override
  String get lyricsMenuEdit => 'Edit lyrics';

  @override
  String get lyricsEditTitle => 'Set lyrics';

  @override
  String get lyricsEditLabel => 'Lyrics';

  @override
  String get lyricsEditHint =>
      'Paste or type the lyrics. Text with times like [01:02.30], or an .lrc / .txt file with them, becomes synced lyrics. Save empty to remove them.';

  @override
  String get lyricsEditSyncedHint =>
      'Times on the left follow the line number. If you insert or delete a line, the times stay in place and only the text shifts. Change times in the sync screen.';

  @override
  String get lyricsAddLine => 'Add line';

  @override
  String get lyricsDeleteLine => 'Delete line';

  @override
  String get lyricsTimePrev => 'Previous';

  @override
  String get lyricsTimeNow => 'Now';

  @override
  String get lyricsTimeNext => 'Next';

  @override
  String get lyricsTimeNone => 'None';

  @override
  String get lyricsTimeGroupedAbove =>
      'Same time as the line above, so they are grouped';

  @override
  String get lyricsTimeGroupedBelow =>
      'Same time as the line below, so they are grouped';

  @override
  String get lyricsTimeSeparate => 'Split from the group here';

  @override
  String get lyricsTimeClearFrom => 'Clear sync from here';

  @override
  String get lyricsLoadFile => 'Load from file';

  @override
  String get lyricsWebSearch => 'Import from the web';

  @override
  String get lyricsWebTitle => 'Search lyrics';

  @override
  String get lyricsWebHint =>
      'Long-press and drag to select text, then tap Add. Add as many times as you like, then tap Import.';

  @override
  String get lyricsWebImport => 'Import';

  @override
  String get lyricsWebNothingSelected =>
      'Nothing is selected. Select the lyrics first.';

  @override
  String get lyricsWebAdd => 'Add';

  @override
  String get lyricsWebScratchTitle => 'Collected text';

  @override
  String get lyricsWebScratchHint =>
      'Added text piles up here. You can edit or delete it.';

  @override
  String get lyricsWebClear => 'Clear all';

  @override
  String get lyricsWebScratchEmpty =>
      'Nothing collected yet. Select lyrics and tap Add first.';

  @override
  String get lyricsSave => 'Save';

  @override
  String get lyricsSaved => 'Lyrics saved';

  @override
  String get lyricsCleared => 'Lyrics removed';

  @override
  String get lyricsSyncTitle => 'Sync lyrics';

  @override
  String get lyricsSyncSetting => 'Sync settings';

  @override
  String get lyricsSyncHint =>
      'Tap \'Now\' along with the song to stamp each line. Tap a stamped line to fine-tune its time.';

  @override
  String get lyricsSyncNow => 'Now';

  @override
  String get lyricsSyncUndo => 'Undo';

  @override
  String get lyricsSyncPrevious => 'Remove last sync and go back';

  @override
  String get lyricsSyncSavePartial => 'Save progress (up to the stamped lines)';

  @override
  String get lyricsSyncSave => 'Save sync';

  @override
  String get lyricsSyncGroup => 'Lines per sync';

  @override
  String lyricsSyncGroupLines(int n) {
    return '$n';
  }

  @override
  String get lyricsSyncNeedAll => 'Stamp every line to save.';

  @override
  String get lyricsSyncEmpty => 'No lyrics to sync. Add lyrics first.';

  @override
  String get lyricsTagNotSaved =>
      'Couldn\'t save to the file. Clearing app data will lose the lyrics.';

  @override
  String get lyricsSyncPlay => 'Play';

  @override
  String get lyricsSyncPause => 'Pause';

  @override
  String lyricsSyncBackBy(double n) {
    return 'Back ${n}s (long-press to change)';
  }

  @override
  String lyricsSyncForwardBy(double n) {
    return 'Forward ${n}s (long-press to change)';
  }

  @override
  String get lyricsSyncAutoPause => 'Auto pause';

  @override
  String get lyricsSyncAutoPauseHint =>
      'Pause when playback reaches the next line\'s existing sync';

  @override
  String get lyricsSyncSeek => 'Playback position';

  @override
  String lyricsSyncProgress(int done, int total) {
    return '$done/$total lines';
  }

  @override
  String get lyricsImportExistsTitle => 'Lyrics already exist';

  @override
  String get lyricsImportExistsBody =>
      'How should the imported lyrics be added?';

  @override
  String get lyricsImportReplace => 'Replace';

  @override
  String get lyricsImportAppend => 'Append';

  @override
  String get lyricsImportMemo => 'Add to note';

  @override
  String get lyricsMemoTitle => 'Note';

  @override
  String get lyricsMemoHide => 'Hide note';

  @override
  String get lyricsMemoHint =>
      'Edit or select text, then tap Insert to add it below the current line';

  @override
  String get lyricsMemoInsert => 'Insert';

  @override
  String get lyricsSyncGroupSetupBody =>
      'Pick how many lines to stamp at once. You can change it later from the top menu.';

  @override
  String get lyricsSyncLeaveTitle => 'Sync is not saved';

  @override
  String get lyricsSyncLeaveBody =>
      'Not every line has a time yet, so leaving now discards your timing. Save what you have before leaving?';

  @override
  String get lyricsSyncLeaveSave => 'Save and leave';

  @override
  String get lyricsSyncLeaveDiscard => 'Leave without saving';

  @override
  String get lyricsSyncLeaveStay => 'Keep syncing';

  @override
  String get lyricsSyncGroupOk => 'OK';

  @override
  String get lyricsSyncDefaultLines => 'Change default lines';

  @override
  String get lyricsSyncExpandedHint =>
      'Lines shown separately · set each time; tap outside to re-merge lines with the same time';

  @override
  String get lyricsSyncCancelAfter => 'Reset to this sync';

  @override
  String get lyricsSyncCancelAfterHint =>
      'Clear the syncs stamped after this one and continue from here';

  @override
  String get lyricsSyncNextSlot => 'Next';

  @override
  String get lyricsSyncFollow => 'Follow';

  @override
  String get lyricsSyncFollowHint =>
      'On: the list follows the focused line. Off: browse the lyrics freely';

  @override
  String get lyricsFollow => 'Follow lyrics';

  @override
  String get lyricsThemeList => 'List';

  @override
  String get lyricsThemeCentered => 'Centered line';

  @override
  String get lyricsThemeCover => 'Cover background';

  @override
  String get themeTabPlayer => 'Player';

  @override
  String get themeTabLyrics => 'Lyrics';

  @override
  String get lyricsLatencyTitle => 'Reaction time';

  @override
  String get lyricsLatencyEntry => 'Reaction time';

  @override
  String get lyricsLatencyIntro =>
      'When you press Now after hearing the sound, the stamp lands late by your reaction time. The value below is subtracted from the time you pressed.';

  @override
  String lyricsLatencySeconds(String s) {
    return '${s}s';
  }

  @override
  String get lyricsLatencyReset => 'Reset to 0.20s';

  @override
  String get lyricsBeatTitle => 'Beat test';

  @override
  String get lyricsBeatBody =>
      'The circle flashes with a sound. Tap the circle on every beat. After 8 taps the average gives a recommended value.';

  @override
  String get lyricsBeatIdle => 'Press Start';

  @override
  String lyricsBeatProgress(int n, int total) {
    return '$n/$total';
  }

  @override
  String get lyricsBeatStart => 'Start';

  @override
  String get lyricsBeatStop => 'Stop';

  @override
  String lyricsBeatResult(String s) {
    return 'Recommended ${s}s';
  }

  @override
  String get lyricsBeatApply => 'Apply this value';

  @override
  String get lyricsBeatNote =>
      'Screen and sound delay differ by device, so this is tuned for Android. Desktop may be less accurate.';

  @override
  String get lyricsSongCheckTitle => 'Check with a song';

  @override
  String get lyricsSongCheckBody =>
      'While the song plays, press Try stamp the moment a sound starts. Listen again from the stamped position to check it.';

  @override
  String get lyricsSongTry => 'Try stamp';

  @override
  String lyricsSongTried(String clock) {
    return 'Stamped at $clock';
  }

  @override
  String get lyricsSongListen => 'Listen from stamp';

  @override
  String get lyricsSyncSkipTitle => 'Stamped syncs will be lost';

  @override
  String get lyricsSyncSkipBody =>
      'The range contains syncs you already stamped. Merging it into one block removes them. Continue?';

  @override
  String get lyricsSyncSkipConfirm => 'Merge';

  @override
  String get lyricsSyncResetTitle => 'Groupings will be lost';

  @override
  String get lyricsSyncResetBody =>
      'Changing the default line count removes custom groupings and stamped times, and splits the lyrics again with the chosen count. Continue?';

  @override
  String get lyricsSyncResetConfirm => 'Change';

  @override
  String lyricsSyncMerged(int n) {
    return '$n lines share one time';
  }

  @override
  String get lyricsSyncUnmerge => 'Split';

  @override
  String get playerLyricsExpand => 'Lyrics only';

  @override
  String get playerLyricsCollapse => 'Close lyrics';

  @override
  String get playerShowLyrics => 'Show lyrics';

  @override
  String get playerShowCover => 'Show cover';

  @override
  String get lyricsEmpty => 'No lyrics yet';

  @override
  String get lyricsEmptyHint =>
      'Put a .lrc file with the same name next to the song, or add lyrics yourself.';

  @override
  String get playlistFavorites => 'Favorites';

  @override
  String get playlistMenuTooltip => 'Playlist menu';

  @override
  String get playlistFeaturedTitle => 'Featured song';

  @override
  String get playlistFeaturedPreview => 'Preview featured song';

  @override
  String get playlistMenuPlayAll => 'Play all';

  @override
  String get playlistMenuShuffle => 'Shuffle play';

  @override
  String get playlistMenuRename => 'Rename';

  @override
  String get playlistMenuDelete => 'Delete playlist';

  @override
  String get playlistPlayEmpty => 'No songs to play';

  @override
  String get playlistRenameTitle => 'Rename';

  @override
  String get playlistRenameSave => 'Save';

  @override
  String get playlistDeleteTitle => 'Delete this playlist?';

  @override
  String playlistDeleteBody(String name) {
    return '‘$name’ will be deleted. Its songs stay in your library.';
  }

  @override
  String get playlistDeleteConfirm => 'Delete';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get playlistNewImage => 'Choose image';

  @override
  String get playlistNewImageChange => 'Change image';

  @override
  String get playlistPickTitle => 'Choose playlists';

  @override
  String get playlistPickHint => 'Pick the playlists to add to';

  @override
  String get playlistPickDone => 'Done';

  @override
  String get playlistPickAlready => 'Already added';

  @override
  String get filterAllArtists => 'All artists';

  @override
  String get filterAllAlbums => 'All albums';

  @override
  String get filterAllGenres => 'All genres';

  @override
  String get playlistAddTracks => 'Add songs';

  @override
  String get playlistAddTracksTitle => 'Add songs';

  @override
  String playlistAddTracksStart(int count) {
    return 'Add $count';
  }

  @override
  String get playlistAddTracksEmptyTitle => 'No songs to add';

  @override
  String get playlistAddTracksEmptyBody =>
      'All songs in your library are already here, or nothing matches the search.';

  @override
  String get playlistDetailEmpty => 'No songs yet';

  @override
  String get playlistDetailEmptyFavorites => 'No liked songs yet';

  @override
  String get playlistDetailEmptyBody =>
      'Use \"Add to playlist\" in a song\'s menu, or \"Add songs\" below.';

  @override
  String get playlistDetailEmptyFavoritesBody =>
      'Songs you like from the song menu show up here.';

  @override
  String get playlistNotFound => 'Playlist not found';

  @override
  String get albumNotFound => 'Album not found';

  @override
  String get playerQueueEmpty => 'The queue is empty';

  @override
  String get trackMenuFavorite => 'Favorite';

  @override
  String get trackMenuUnfavorite => 'Remove from favorites';

  @override
  String get trackFavoriteOn => 'Added to favorites';

  @override
  String get trackFavoriteOff => 'Removed from favorites';

  @override
  String get playlistImportHint => 'Playlist name or link';

  @override
  String get playlistImportEmptyTitle => 'Find a playlist';

  @override
  String get playlistImportEmptyBody =>
      'Search by name or paste a link, then pick the tracks to download.';

  @override
  String get playlistImportNoResultsTitle => 'No playlists found';

  @override
  String get playlistImportNoResultsBody => 'Try a different search.';

  @override
  String get playlistImportLoading => 'Reading the track list…';

  @override
  String playlistImportSelectedCount(int selected, int total) {
    return '$selected/$total selected';
  }

  @override
  String playlistImportResultSubtitle(String channel, int count) {
    return '$channel · $count songs';
  }

  @override
  String get playlistImportNotPlaylistTitle => 'That is not a playlist link';

  @override
  String get playlistImportNotPlaylistBody =>
      'This link is a single track. Paste a playlist link instead.';

  @override
  String get playlistImportNoTracksTitle => 'No tracks';

  @override
  String get playlistImportNoTracksBody =>
      'This playlist has no tracks that can be downloaded.';

  @override
  String get playlistImportSelectAll => 'Select all';

  @override
  String get playlistImportClear => 'Clear selection';

  @override
  String playlistImportStart(int count) {
    return 'Download $count songs';
  }

  @override
  String playlistImportStarted(int count) {
    return 'Started downloading $count songs';
  }

  @override
  String playlistImportStartedSkipped(int count, int skipped) {
    return 'Started downloading $count songs ($skipped already downloaded were skipped)';
  }

  @override
  String get searchPlaylistPick => 'Choose & download';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsGoogleAccount => 'Google account';

  @override
  String get settingsAccountSignedOutDesc =>
      'Sign in to load your YouTube playlists.';

  @override
  String get settingsAccountSignIn => 'Sign in';

  @override
  String get settingsAccountSignOut => 'Sign out';

  @override
  String settingsAccountNotConfigured(String keys) {
    return 'Google sign-in values ($keys) are missing from this build, so it can\'t be used. See docs/google-login-setup.md';
  }

  @override
  String get playlistImportSignInPromptTitle => 'Google sign-in needed';

  @override
  String get playlistImportSignInPromptBody =>
      'Sign in with your Google account to load your YouTube playlists. Sign in now?';

  @override
  String get playlistImportSignInAllow => 'Sign in';

  @override
  String get settingsAccountUnsupported =>
      'Google sign-in is not available on this device';

  @override
  String get settingsAccountFailed => 'Could not sign in. Please try again';

  @override
  String get playlistImportMine => 'My playlists';

  @override
  String get playlistImportMineTitle => 'My YouTube playlists';

  @override
  String get playlistImportMineEmptyTitle => 'No playlists';

  @override
  String get playlistImportMineEmptyBody => 'This account has no playlists.';

  @override
  String get playlistImportLoginTitle => 'Sign in required';

  @override
  String get playlistImportLoginBody =>
      'Sign in with your Google account to load your YouTube playlists.';

  @override
  String get playlistImportLoginExpiredBody =>
      'You were signed out. Please sign in again.';

  @override
  String get playlistImportNoChannelTitle => 'No YouTube channel';

  @override
  String get playlistImportNoChannelBody =>
      'This Google account has no YouTube channel, so your playlists can\'t be loaded. Create a channel on YouTube, or paste a playlist link in the field above. (Private playlists must be set to \"Unlisted\" first.)';

  @override
  String get searchPlaylistFind => 'Find as playlist';

  @override
  String get settingsPermissions => 'Permissions';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsDesc =>
      'Keeps downloads running in the background and shows playback controls.';

  @override
  String get permAudio => 'Music file access';

  @override
  String get permAudioDesc => 'Used to load music stored on this device.';

  @override
  String get permOverlay => 'Display over other apps';

  @override
  String get permOverlayDesc =>
      'Used to show lyrics over other apps while you use them.';

  @override
  String get permBlockedDesc =>
      'Blocked. Tap to turn it on in system settings.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyDownloadProgress => 'Download progress';

  @override
  String get settingsNotifyDownloadProgressDesc =>
      'Shows progress in the notification shade. Downloads keep going when the app is in the background.';

  @override
  String get settingsNotifyDownloadResult => 'Download results';

  @override
  String get settingsNotifyDownloadResultDesc =>
      'Tells you when a download finishes or fails.';

  @override
  String get settingsNotifyPlayback => 'Playback controls';

  @override
  String get settingsNotifyPlaybackDesc =>
      'Control playback from the notification shade and lock screen.';

  @override
  String get lyricsOverlayMinimize => 'Hide';

  @override
  String get lyricsOverlayTurnOff => 'Turn off';

  @override
  String get lyricsOverlayOn => 'Turn on overlay lyrics';

  @override
  String get lyricsOverlayOff => 'Turn off overlay lyrics';

  @override
  String get lyricsOverlayNoLyrics => 'No lyrics';

  @override
  String get lyricsOverlayNotSynced => 'No synced lyrics';

  @override
  String get lyricsOverlayNeedPermission =>
      'Allow \"Display over other apps\" in settings, then turn it on again.';

  @override
  String get settingsNotifyPermission => 'System notifications are off';

  @override
  String get settingsNotifyPermissionDesc =>
      'Turn on Mulo notifications in your phone settings to see them.';

  @override
  String get settingsNotifyOpenSettings => 'Open settings';

  @override
  String get notifHiddenTitle => 'Playing music';

  @override
  String get notifPreviewLabel => 'Preview';

  @override
  String notifSleepAt(String time) {
    return 'Sleep timer at $time';
  }

  @override
  String get notifHiddenNote => 'Song info hidden';

  @override
  String notifHiddenNotePosition(String n, String total) {
    return 'Song info hidden · track $n of $total';
  }

  @override
  String get notifStop => 'Close';

  @override
  String get notifChannelPlayback => 'Playback';

  @override
  String get notifChannelDownloadProgress => 'Downloading';

  @override
  String get notifChannelDownloadDone => 'Download complete';

  @override
  String get notifChannelDownloadFailed => 'Download failed';

  @override
  String get notifDownloadHiddenTitle => 'Downloading a song';

  @override
  String notifDownloadProgressBody(int percent) {
    return 'Downloading · $percent%';
  }

  @override
  String notifDownloadProgressNext(int percent, String next) {
    return 'Downloading · $percent% · Next: $next';
  }

  @override
  String notifDownloadOverall(int done, int total, int percent) {
    return 'Overall $done/$total · $percent%';
  }

  @override
  String get notifDownloadPreview => 'Preview';

  @override
  String get notifDownloadCancel => 'Cancel';

  @override
  String get notifDownloadPause => 'Pause';

  @override
  String get notifDownloadResume => 'Resume download';

  @override
  String notifDownloadPausedBody(int percent) {
    return 'Paused · $percent%';
  }

  @override
  String get notifDownloadPausePreview => 'Pause';

  @override
  String get notifDownloadResumePreview => 'Resume';

  @override
  String get notifDownloadStopPreview => 'Stop';

  @override
  String get notifDownloadDoneTitle => 'Download complete';

  @override
  String get notifDownloadDoneHidden => 'A song was added to your library';

  @override
  String get notifDownloadFailedTitle => 'Download failed';

  @override
  String get notifDownloadFailedHidden => 'A song could not be downloaded';

  @override
  String get subscribeAction => 'Subscribe';

  @override
  String get subscribedAction => 'Subscribed';

  @override
  String get subscribeAdded =>
      'Subscribed. You\'ll be told about videos posted from now on';

  @override
  String get subscribeFailed => 'This channel can\'t be subscribed to';

  @override
  String get unsubscribed => 'Unsubscribed';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String get subscriptionsSubtitle => 'Pick new videos to download';

  @override
  String get subscriptionsEmptyTitle => 'No subscribed channels';

  @override
  String get subscriptionsEmptyBody =>
      'Tap Subscribe on a video\'s channel and you can pick new videos to download when they are posted.';

  @override
  String get subscriptionsNewVideos => 'See new videos';

  @override
  String get subscriptionsUnsubscribe => 'Unsubscribe';

  @override
  String subscriptionsCount(int count) {
    return '$count channels';
  }

  @override
  String get newVideosTitle => 'New videos';

  @override
  String get newVideosChecking => 'Checking for new videos';

  @override
  String get newVideosEmptyTitle => 'No new videos';

  @override
  String get newVideosEmptyBody =>
      'When subscribed channels post new videos, you can pick them to download here.';

  @override
  String newVideosSummary(int channels, int videos) {
    return '$channels channels · $videos videos';
  }

  @override
  String newVideosStart(int count) {
    return 'Download $count';
  }

  @override
  String newVideosStarted(int count) {
    return 'Started downloading $count songs';
  }

  @override
  String get newVideosSkipped => 'Those songs are already downloaded';

  @override
  String get newVideosClear => 'Clear';

  @override
  String get newVideosClearTitle => 'Clear the new videos list?';

  @override
  String get newVideosClearBody =>
      'Videos you have not downloaded also leave the list and will not show up again. Only videos posted from now on appear as new.';

  @override
  String get newVideosSelectAll => 'Select all';

  @override
  String get newVideosSelectNone => 'Clear selection';

  @override
  String newVideosAnnounce(int count) {
    return '$count new videos from your subscriptions';
  }

  @override
  String get newVideosOpen => 'View';

  @override
  String get settingsSubscriptions => 'Subscriptions';

  @override
  String get settingsSubscriptionChannels => 'Subscribed channels';

  @override
  String get settingsCheckOnLaunch => 'Check for new videos on launch';

  @override
  String get settingsCheckOnLaunchDesc =>
      'Tell me when subscribed channels have new videos and let me pick what to download.';

  @override
  String get settingsBackgroundCheck => 'Check even when the app is closed';

  @override
  String get settingsBackgroundCheckDesc =>
      'Checks periodically and notifies you of new videos.';

  @override
  String get settingsCheckInterval => 'Check every';

  @override
  String settingsCheckIntervalHours(int count) {
    return '${count}h';
  }

  @override
  String get settingsCheckWifiOnly => 'Check on Wi-Fi only';

  @override
  String get settingsCheckWifiOnlyDesc =>
      'Only checks while connected to Wi-Fi to save mobile data.';

  @override
  String get settingsCheckNow => 'Check now';

  @override
  String get settingsCheckNowChecking => 'Checking…';

  @override
  String get settingsCheckStatusNever => 'Not checked yet.';

  @override
  String settingsCheckStatusLast(String time) {
    return 'Last checked $time';
  }

  @override
  String settingsCheckStatusNotified(int count) {
    return 'Notified $count new videos.';
  }

  @override
  String settingsCheckStatusFailed(int count) {
    return 'Could not read $count channels.';
  }

  @override
  String get settingsCheckStatusBlocked =>
      'Notifications are off, so new videos were not announced. Turn on Mulo notifications (including New videos) in device settings.';

  @override
  String get settingsCheckStatusNotScheduled =>
      'Periodic checking is not scheduled. Try turning the switch above off and on.';

  @override
  String get notifChannelNewVideos => 'New videos';

  @override
  String get notifNewVideosTitle => 'New videos from your subscriptions';

  @override
  String notifNewVideosBody(String channels, String count) {
    return '$channels · $count new videos';
  }

  @override
  String get channelSearchTitle => 'Find channels';

  @override
  String get channelSearchHint => 'Search by channel name';

  @override
  String get channelSearchIdle => 'Search for a channel to subscribe to';

  @override
  String get channelSearchLoading => 'Searching for channels';

  @override
  String get channelSearchEmpty => 'No channels found';

  @override
  String get channelSearchFailed =>
      'Couldn\'t search for channels. Please try again later';

  @override
  String get categoryAll => 'All categories';

  @override
  String get subscriptionsCategories => 'Categories to be notified about';

  @override
  String get subscriptionsCategoriesDesc =>
      'Only new videos in the chosen categories are shown and notified. Pick none for all categories.';

  @override
  String channelInfoVideoCount(int count) {
    return '$count videos';
  }

  @override
  String get channelSaveFolder => 'Save folder';

  @override
  String get channelSaveFolderDefault => 'Default save folder';

  @override
  String get channelSaveFolderChange => 'Change';

  @override
  String get channelSaveFolderReset => 'Use default';

  @override
  String get notifNewVideoDownloadNow => 'Download now';

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerOn => 'On';

  @override
  String get equalizerOff => 'Off';

  @override
  String get equalizerUnsupported =>
      'The equalizer isn\'t available on this device';

  @override
  String get equalizerEnable => 'Use equalizer';

  @override
  String get equalizerEnableDesc =>
      'Shapes the sound with the settings below. Off by default.';

  @override
  String get equalizerDeviceProfile => 'Save for this device only';

  @override
  String equalizerDeviceProfileDesc(String device) {
    return 'Applies these settings automatically when $device is connected.';
  }

  @override
  String get equalizerMyPresets => 'My presets';

  @override
  String get equalizerMyPresetsHint => 'Long-press to delete';

  @override
  String get equalizerPresetSaveNew => 'Save current';

  @override
  String get equalizerPresetNameTitle => 'Preset name';

  @override
  String get equalizerPresetNameHint => 'e.g. Earbuds, Car';

  @override
  String get equalizerPresetSave => 'Save';

  @override
  String get equalizerPresetDeleteTitle => 'Delete preset';

  @override
  String equalizerPresetDeleteBody(String name) {
    return 'Delete \"$name\"? Devices using it keep their last values';
  }

  @override
  String get equalizerDevicesTitle => 'Equalizer per device';

  @override
  String get equalizerDevicesEmpty =>
      'No Bluetooth or earphone devices connected yet';

  @override
  String get equalizerDeviceDefault => 'Default settings';

  @override
  String get equalizerDeviceCustom => 'Custom';

  @override
  String get equalizerDeviceEdit => 'Edit in equalizer';

  @override
  String get equalizerEditingDevice => 'Editing the settings for this device';

  @override
  String get equalizerDeviceCurrent => 'Connected now';

  @override
  String equalizerDevicePickTitle(String device) {
    return 'Preset for $device';
  }

  @override
  String get equalizerDeviceNoPresets =>
      'Create a preset first with \"Save current\" on the equalizer screen';

  @override
  String get equalizerPreset => 'Presets';

  @override
  String get equalizerBands => 'Bands';

  @override
  String get equalizerBassBoost => 'Bass boost';

  @override
  String get equalizerBassBoostDesc => 'Makes low sounds heavier.';

  @override
  String get equalizerReset => 'Reset';

  @override
  String get equalizerPresetFlat => 'Flat';

  @override
  String get equalizerPresetBass => 'Bass';

  @override
  String get equalizerPresetTreble => 'Treble';

  @override
  String get equalizerPresetVocal => 'Vocal';

  @override
  String get equalizerPresetRock => 'Rock';

  @override
  String get equalizerPresetPop => 'Pop';

  @override
  String get equalizerPresetJazz => 'Jazz';

  @override
  String get equalizerPresetClassical => 'Classical';

  @override
  String get equalizerPresetDance => 'Hip-hop / EDM';

  @override
  String get equalizerPresetCustom => 'Custom';

  @override
  String get equalizerVirtualizer => 'Spatial sound';

  @override
  String get equalizerVirtualizerDesc => 'Widens the sound on headphones.';

  @override
  String get equalizerReverb => 'Reverb';

  @override
  String get equalizerReverbDesc => 'Adds the echo of a room or hall.';

  @override
  String get equalizerLimiter => 'Prevent clipping';

  @override
  String get equalizerLimiterDesc => 'Keeps loud sound from distorting.';

  @override
  String get equalizerReverbNone => 'None';

  @override
  String get equalizerReverbSmallRoom => 'Small room';

  @override
  String get equalizerReverbMediumRoom => 'Medium room';

  @override
  String get equalizerReverbLargeRoom => 'Large room';

  @override
  String get equalizerReverbMediumHall => 'Medium hall';

  @override
  String get equalizerReverbLargeHall => 'Large hall';

  @override
  String get equalizerReverbPlate => 'Plate';

  @override
  String get equalizerSave => 'Save';

  @override
  String get audioLanguageTitle => 'Audio language';

  @override
  String get audioLanguageRow => 'Audio language';

  @override
  String get audioLanguageOriginal => 'Original';

  @override
  String get audioLanguageHint =>
      'Applies right away. Preview and download use the same language.';

  @override
  String get downloadAgainTitle => 'Download again?';

  @override
  String get downloadAgainBody =>
      'This song is already downloaded. Downloading it again adds another copy.';

  @override
  String get downloadAgainConfirm => 'Download again';

  @override
  String selectCount(int count) {
    return '$count selected';
  }

  @override
  String get selectClose => 'Done selecting';

  @override
  String get selectAssignAlbum => 'Set album';

  @override
  String get selectAssignArtist => 'Set artist';

  @override
  String get selectAssignGenre => 'Set genre';

  @override
  String get selectAssignAlbumTitle => 'Change album';

  @override
  String get selectAssignArtistTitle => 'Change artist';

  @override
  String get selectAssignGenreTitle => 'Change genre';

  @override
  String selectConfirmAlbum(int count, String value) {
    return 'Change the album of the $count selected songs?\n\nNew album: $value\n\nThey leave their other albums, and the music files\' info changes too.';
  }

  @override
  String selectConfirmArtist(int count, String value) {
    return 'Change the artist of the $count selected songs?\n\nNew artist: $value\n\nThey leave their other artists, and the music files\' info changes too.';
  }

  @override
  String selectConfirmGenre(int count, String value) {
    return 'Change the genre of the $count selected songs?\n\nNew genre: $value\n\nThey leave their other genres, and the music files\' info changes too.';
  }

  @override
  String get selectConfirmApply => 'Apply';

  @override
  String selectAssignPartial(int count) {
    return '$count songs could not be written to their music files and were left unchanged.';
  }

  @override
  String get selectActions => 'Actions';

  @override
  String get selectAssignHintAlbum =>
      'Enter the album for all selected songs. Leave it empty to clear the album.';

  @override
  String get selectAssignHintArtist =>
      'Enter the artist for all selected songs. Leave it empty to clear the artist.';

  @override
  String get selectAssignHintGenre =>
      'Enter the genre for all selected songs. Leave it empty to clear the genre.';

  @override
  String get selectNext => 'Next';

  @override
  String get playlistImportChannels => 'Playlists of subscribed channels';

  @override
  String get channelPickTitle => 'Pick a channel';

  @override
  String get channelPickEmpty =>
      'You have not subscribed to any channel yet. You can import your YouTube subscriptions below.';

  @override
  String get channelPlaylistsUploads => 'All uploads';

  @override
  String get channelImportOpen => 'Pick channels from my YouTube subscriptions';

  @override
  String get channelImportTitle => 'My subscribed channels';

  @override
  String get channelImportHint =>
      'Tap channels to pick them. Only the channels you pick are added, nothing is imported all at once.';

  @override
  String get channelImportAlready => 'Subscribed';

  @override
  String channelImportLoading(int count) {
    return 'Loading subscriptions… $count so far';
  }

  @override
  String get channelImportEmptyTitle => 'No subscribed channels';

  @override
  String get channelImportEmptyBody =>
      'This Google account has not subscribed to any channel on YouTube.';

  @override
  String get channelImportSignInBody =>
      'Sign in with Google to load your YouTube subscriptions.';

  @override
  String channelImportSelectCount(int count) {
    return '$count channels selected';
  }

  @override
  String get channelImportSelectNew => 'Select all new channels';

  @override
  String get channelImportSubscribe => 'Subscribe to picked channels';

  @override
  String get channelImportConfirmTitle => 'Subscribe to channels';

  @override
  String channelImportConfirmBody(int count) {
    return 'Subscribe to the $count picked channels? You will be told about videos posted from now on.';
  }

  @override
  String channelImportDone(int count) {
    return 'Subscribed to $count channels';
  }
}
