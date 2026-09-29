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
  String get downloadsSubtitle => 'Queue';

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
  String get sortName => 'Name';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortArtist => 'Artist';

  @override
  String get libraryImport => 'Import device music';

  @override
  String libraryStorage(String size) {
    return '$size used';
  }

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
  String get settingsServerAddress => 'Server address';

  @override
  String get settingsServerNotSet => 'Not set';

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
  String get settingsPlayback => 'Playback';

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
}
