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
      'Paste a URL or type keywords.\nShare from the YouTube app to open it here.';

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
  String get qualityBest => 'Best';

  @override
  String get qualityNormal => 'Normal';

  @override
  String get qualitySaver => 'Saver';

  @override
  String get downloadsActive => 'Active';

  @override
  String downloadsWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get downloadsPauseAll => 'Pause all';

  @override
  String get downloadsClearDone => 'Clear finished';

  @override
  String get statusDownloading => 'Downloading';

  @override
  String get statusQueued => 'Queued';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusFailed => 'Failed';

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
  String get genreBack => 'Back to genres';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortName => 'Name';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortArtist => 'Artist';

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
  String get loadedFoldersScanning => 'Rescanning your library';

  @override
  String get settingsQuality => 'Default quality';

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
  String get settingsHideNotification => 'Hide song info in notification';

  @override
  String get settingsHideNotificationDesc =>
      'Shows only \"Playing music\" on notifications and lock screen.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsFollowMood => 'Follow song mood';

  @override
  String get settingsFollowMoodDesc =>
      'Accent colors follow the current song\'s cover.';

  @override
  String get settingsThemeColor => 'Theme color';

  @override
  String get settingsDesignPreview => 'Design preview';

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
  String get playerRepeat => 'Repeat';

  @override
  String get playerLyrics => 'Lyrics';

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
  String get coverTitle => 'Cover image';

  @override
  String get coverChange => 'Change cover';

  @override
  String get coverPick => 'Choose from photos';

  @override
  String get coverReset => 'Use default';

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
  String get homeRecommendations => 'For you';

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
  String playCount(int count) {
    return '$count plays';
  }

  @override
  String get searchHintWeb => 'Web audio search or URL';

  @override
  String get searchSourceTooltip => 'Search source';

  @override
  String get sourceYoutube => 'YouTube';

  @override
  String get sourceWeb => 'Web';

  @override
  String get downloadsExpand => 'Show queue';

  @override
  String get downloadsCollapse => 'Hide queue';

  @override
  String get downloadDialogTitle => 'Download details';

  @override
  String get downloadFieldTitle => 'Title';

  @override
  String get downloadFieldArtist => 'Artist';

  @override
  String get downloadFieldGenre => 'Genre';

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
  String get playlistMenuImage => 'Change image';

  @override
  String get playlistMenuColor => 'Card color';

  @override
  String get playlistColorAuto => 'Auto';

  @override
  String playlistColorOption(String name) {
    return 'Card color $name';
  }

  @override
  String get playlistColorPrimary => 'Primary';

  @override
  String get playlistColorSecondary => 'Secondary';

  @override
  String get playlistColorTertiary => 'Accent';

  @override
  String get playlistSummaryEmpty => 'Empty';

  @override
  String get dpTitle => 'Preview';

  @override
  String get dpPaletteDefault => 'Default';

  @override
  String get dpPaletteAlt => 'Alternate palette';

  @override
  String get dpQueueWaiting => 'songs waiting';

  @override
  String get dpPlayedToday => 'Played today';

  @override
  String get dpHours => 'hours';

  @override
  String get dpSectionButtons => 'Buttons';

  @override
  String get dpDisabled => 'Disabled';

  @override
  String get dpLike => 'Like';

  @override
  String get dpSectionProgress => 'Progress';

  @override
  String get dpSectionType => 'Type';

  @override
  String get dpHeadline => 'Headline Title';

  @override
  String get dpTitleSample => 'Title Song title';

  @override
  String get dpBody => 'Body text sample.';

  @override
  String get dpCaption => 'Caption Helper text';

  @override
  String get dpSongsSize => 'songs · 9.4 GB';

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
}
