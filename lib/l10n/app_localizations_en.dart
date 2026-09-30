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
}
