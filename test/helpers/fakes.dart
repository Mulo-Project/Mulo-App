import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/account/di.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';
import 'package:music_download_play_app/features/account/domain/repositories/account_repository.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/lyrics/di.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/covers/domain/repositories/cover_repository.dart';
import 'package:music_download_play_app/features/downloads/di.dart';
import 'package:music_download_play_app/features/engine/di.dart';
import 'package:music_download_play_app/features/engine/domain/entities/engine_status.dart';
import 'package:music_download_play_app/features/engine/domain/repositories/engine_manager.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_source.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_settings_repository.dart';
import 'package:music_download_play_app/features/home/di.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/repositories/join_date_repository.dart';
import 'package:music_download_play_app/features/home/domain/repositories/play_history_repository.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/entities/track_info.dart';
import 'package:music_download_play_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_download_play_app/features/notifications/di.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/media_session_info.dart';
import 'package:music_download_play_app/features/notifications/domain/entities/notification_settings.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/download_notifier.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/media_session.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/notification_settings_repository.dart';
import 'package:music_download_play_app/features/permissions/di.dart';
import 'package:music_download_play_app/features/permissions/domain/entities/app_permission.dart';
import 'package:music_download_play_app/features/permissions/domain/repositories/permission_repository.dart';
import 'package:music_download_play_app/features/player/di.dart';
import 'package:music_download_play_app/features/player/domain/entities/player_style.dart';
import 'package:music_download_play_app/features/player/domain/repositories/audio_player_repository.dart';
import 'package:music_download_play_app/features/player/domain/repositories/player_style_repository.dart';
import 'package:music_download_play_app/features/playlists/di.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_download_play_app/features/search/di.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';
import 'package:music_download_play_app/features/search/domain/entities/preview_progress.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_source.dart';
import 'package:music_download_play_app/features/search/domain/repositories/downloader_engine.dart';
import 'package:music_download_play_app/features/search/domain/repositories/link_opener.dart';
import 'package:music_download_play_app/features/search/domain/repositories/preview_player.dart';
import 'package:music_download_play_app/features/security/di.dart';
import 'package:music_download_play_app/features/security/domain/entities/app_lock_settings.dart';
import 'package:music_download_play_app/features/security/domain/repositories/app_lock_repository.dart';
import 'package:music_download_play_app/features/theme/di.dart';
import 'package:music_download_play_app/features/theme/domain/entities/theme_settings.dart';
import 'package:music_download_play_app/features/theme/domain/repositories/theme_settings_repository.dart';

/// 메모리 보관함.
class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository([List<Track> initial = const []])
    : _tracks = [...initial];

  final List<Track> _tracks;
  final _changes = StreamController<List<Track>>.broadcast();

  List<Track> get _sorted =>
      [..._tracks]..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  @override
  Stream<List<Track>> watchTracks() async* {
    yield _sorted;
    yield* _changes.stream;
  }

  @override
  Future<int> addTracks(List<Track> tracks) async {
    final uris = _tracks.map((t) => t.uri).toSet();
    final added = tracks.where((t) => uris.add(t.uri)).toList();
    _tracks.addAll(added);
    _changes.add(_sorted);
    return added.length;
  }

  @override
  Future<bool> updateInfo(String trackId, TrackInfo info) async {
    final i = _tracks.indexWhere((t) => t.id == trackId);
    if (i < 0) return false;
    final t = _tracks[i];
    _tracks[i] = Track(
      id: t.id,
      title: info.title,
      artist: info.artist,
      album: info.album,
      genre: info.genre,
      duration: t.duration,
      addedAt: t.addedAt,
      uri: t.uri,
      folder: t.folder,
      source: t.source,
    );
    _changes.add(_sorted);
    return true;
  }

  @override
  Future<void> delete(String trackId) async {
    _tracks.removeWhere((t) => t.id == trackId);
    _changes.add(_sorted);
  }
}

/// 메모리 음악 파일 (지운 곡 id를 기록한다. [succeeds]가 false면 지우기 실패).
class FakeTrackFiles implements TrackFileRepository {
  FakeTrackFiles({this.succeeds = true});

  bool succeeds;
  final deleted = <String>[];

  @override
  Future<bool> deleteFile(Track track) async {
    if (succeeds) deleted.add(track.id);
    return succeeds;
  }
}

/// 메모리 불러오는 폴더 목록 (고르기는 [picked]를 그대로 돌려준다).
class MemoryLoadedFolders implements LoadedFolderRepository {
  MemoryLoadedFolders({this.picked, List<String> extra = const []})
    : extra = [...extra];

  String? picked;
  List<String> extra;

  @override
  String get defaultFolder => '/music/default';

  @override
  Future<List<String>> loadExtra() async => [...extra];

  @override
  Future<void> saveExtra(List<String> folders) async => extra = [...folders];

  @override
  Future<String?> pickFolder() async => picked;
}

class FakeDeviceMusic implements DeviceMusicRepository {
  FakeDeviceMusic(this.result);

  ScanResult result;
  int calls = 0;

  /// 마지막 scan에 넘어온 폴더.
  List<String> lastFolders = const [];

  @override
  Future<ScanResult> scan(List<String> folders) async {
    calls++;
    lastFolders = folders;
    return result;
  }
}

/// 파일 복사 없이 경로 · 주소만 기억하는 커버 저장소.
class MemoryCoverRepository implements CoverRepository {
  final saved = <String, CoverArt>{};

  @override
  Future<Map<String, CoverArt>> loadAll() async => {...saved};

  @override
  Future<CoverArt> save(
    String key,
    String sourcePath, {
    CoverTransform transform = CoverTransform.identity,
  }) async => saved[key] = CoverArt.file(sourcePath, transform: transform);

  @override
  Future<CoverArt> saveUrl(
    String key,
    String url, {
    CoverTransform transform = CoverTransform.identity,
  }) async => saved[key] = CoverArt.web(url, transform: transform);

  @override
  Future<void> saveTransform(String key, CoverTransform transform) async {
    final art = saved[key];
    if (art != null) saved[key] = art.withTransform(transform);
  }

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

/// 메모리 다운로드 설정 저장소. [picked]는 폴더 선택기가 고를 경로 (null이면 취소).
class MemoryDownloadSettings implements DownloadSettingsRepository {
  MemoryDownloadSettings({this.path = '/music/Mulo', this.picked});

  String path;
  String? picked;

  @override
  List<AudioFormat> selectableFormats() => formats;

  /// 설정에서 고를 수 있는 저장 형식 (기본은 전부).
  List<AudioFormat> formats = AudioFormat.values;

  @override
  Future<String> loadSavePath() async => path;

  @override
  Future<void> saveSavePath(String value) async => path = value;

  Quality quality = Quality.best;
  AudioFormat format = AudioFormat.opus;

  @override
  Future<Quality> loadQuality() async => quality;

  @override
  Future<void> saveQuality(Quality value) async => quality = value;

  @override
  Future<AudioFormat> loadFormat() async => format;

  @override
  Future<void> saveFormat(AudioFormat value) async => format = value;

  @override
  Future<String?> pickFolder() async => picked;
}

/// 메모리 커버 색 저장소.
class MemoryCoverColorRepository implements CoverColorRepository {
  final saved = <String, int>{};

  @override
  Future<Map<String, int>> loadAll() async => {...saved};

  @override
  Future<void> save(String key, int color) async => saved[key] = color;

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

/// 메모리 가사 저장소. [sibling]은 음원 옆 `.lrc`처럼 직접 저장하지 않은 가사.
class MemoryLyricsRepository implements LyricsRepository {
  MemoryLyricsRepository({this.sibling = const {}});

  final saved = <String, String>{};
  final Map<String, String> sibling;

  @override
  Future<Lyrics?> load(String trackId, String trackUri) async {
    final text = saved[trackId] ?? sibling[trackId];
    return text == null ? null : Lyrics.parse(text);
  }

  @override
  Future<Lyrics?> save(String trackId, String text) async {
    final lyrics = Lyrics.parse(text);
    if (lyrics == null) {
      saved.remove(trackId);
    } else {
      saved[trackId] = text;
    }
    return lyrics;
  }

  @override
  Future<void> remove(String trackId) async => saved.remove(trackId);
}

class FakeLyricsFileSource implements LyricsFileSource {
  FakeLyricsFileSource([this.result]);

  String? result;
  int calls = 0;

  @override
  Future<String?> pickText() async {
    calls++;
    return result;
  }
}

class FakeImageSource implements CoverImageSource {
  FakeImageSource([this.result]);

  String? result;
  int calls = 0;

  @override
  Future<String?> pickFromDevice() async {
    calls++;
    return result;
  }
}

/// 메모리 앱 잠금 저장소.
class MemoryAppLockRepository implements AppLockRepository {
  MemoryAppLockRepository({this.pin, this.biometric = false});

  String? pin;
  bool biometric;

  @override
  Future<AppLockSettings> load() async => AppLockSettings(
    enabled: pin != null,
    biometricEnabled: pin != null && biometric,
  );

  @override
  Future<void> enable(String newPin) async => pin = newPin;

  @override
  Future<void> disable() async {
    pin = null;
    biometric = false;
  }

  @override
  Future<bool> verifyPin(String candidate) async =>
      pin != null && pin == candidate;

  @override
  Future<void> setBiometric(bool enabled) async => biometric = enabled;
}

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({this.available = false, this.succeeds = true});

  bool available;
  bool succeeds;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return succeeds;
  }
}

/// 메모리 플레이어 모양 저장소.
class MemoryPlayerStyleRepository implements PlayerStyleRepository {
  MemoryPlayerStyleRepository([this.style = PlayerStyle.initial]);

  PlayerStyle style;

  @override
  Future<PlayerStyle> load() async => style;

  @override
  Future<void> save(PlayerStyle value) async => style = value;
}

class MemoryThemeSettingsRepository implements ThemeSettingsRepository {
  MemoryThemeSettingsRepository([this.settings = const ThemeSettings()]);

  ThemeSettings settings;

  @override
  Future<ThemeSettings> load() async => settings;

  @override
  Future<void> savePreset(String presetId) async =>
      settings = ThemeSettings(presetId: presetId, mode: settings.mode);

  @override
  Future<void> saveMode(AppThemeMode mode) async =>
      settings = ThemeSettings(presetId: settings.presetId, mode: mode);
}

/// 메모리 재생 기록.
class MemoryPlayHistory implements PlayHistoryRepository {
  MemoryPlayHistory([List<PlayRecord> initial = const []])
    : plays = [...initial];

  final List<PlayRecord> plays;
  final _changes = StreamController<List<PlayRecord>>.broadcast();

  List<PlayRecord> get _sorted =>
      [...plays]..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  @override
  Future<int> recordPlay(PlayRecord record) async {
    plays.add(record);
    _changes.add(_sorted);
    return plays.length - 1;
  }

  @override
  Future<void> updateListened(int id, Duration listened) async {
    final p = plays[id];
    plays[id] = PlayRecord(
      trackId: p.trackId,
      playedAt: p.playedAt,
      listened: listened,
    );
    _changes.add(_sorted);
  }

  @override
  Stream<List<PlayRecord>> watchPlays() async* {
    yield _sorted;
    yield* _changes.stream;
  }
}

/// 메모리 다운로드 대기열.
class MemoryDownloadQueue implements DownloadQueueRepository {
  MemoryDownloadQueue([List<DownloadItem> initial = const []])
    : items = [...initial];

  final List<DownloadItem> items;
  final _changes = StreamController<List<DownloadItem>>.broadcast();

  void set(List<DownloadItem> next) {
    items
      ..clear()
      ..addAll(next);
    _changes.add([...items]);
  }

  /// 받기 요청 기록.
  final requests = <DownloadRequest>[];

  /// 원본 주소 → 이미 받은 곡 · 받는 중 (재생목록 가져오기 건너뛰기 시험용).
  final existing = <String, ExistingDownload>{};

  @override
  Future<ExistingDownload> findExisting(String url) async =>
      existing[url] ?? ExistingDownload.none;

  @override
  Stream<Set<String>> watchDownloadedKeys() => Stream.value({});

  @override
  Stream<List<DownloadItem>> watchQueue() async* {
    yield [...items];
    yield* _changes.stream;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    requests.add(request);
    items.add(
      DownloadItem(
        id: 'q${requests.length}',
        title: request.title,
        artist: request.artist,
        genre: request.genre,
        playlistIds: request.playlistIds,
        status: DownloadStatus.queued,
      ),
    );
    _changes.add([...items]);
  }

  /// 일시정지 · 이어받기 · 취소 요청 기록.
  final controls = <String>[];

  @override
  Future<int> cancelAll({String? playlistId}) async {
    controls.add('cancelAll:${playlistId ?? ''}');
    final gone = [
      for (final e in items)
        if (e.status != DownloadStatus.done &&
            (playlistId == null || e.playlistIds.contains(playlistId)))
          e,
    ];
    items.removeWhere(gone.contains);
    _changes.add([...items]);
    return gone.length;
  }

  @override
  Future<void> pause(String id) async => controls.add('pause:$id');

  @override
  Future<void> resume(String id) async => controls.add('resume:$id');

  @override
  Future<void> retry(String id) async => controls.add('retry:$id');

  @override
  Future<void> cancel(String id) async => controls.add('cancel:$id');
}

/// 메모리 재생목록.
class MemoryPlaylistRepository implements PlaylistRepository {
  MemoryPlaylistRepository([
    List<Playlist> initial = const [],
    List<Track> tracks = const [],
  ]) : lists = [...initial],
       _tracks = {for (final t in tracks) t.id: t};

  final List<Playlist> lists;
  final Map<String, Track> _tracks;

  /// 재생목록 id → 들어 있는 곡 id (담은 순서).
  final members = <String, Set<String>>{};

  final _changes = StreamController<void>.broadcast();

  PlaylistTrackPreview? _featuredOf(String id, PlaylistTrackPreview? preset) {
    if (preset != null) return preset;
    for (final t in members[id] ?? const <String>{}) {
      final track = _tracks[t];
      if (track != null) {
        return PlaylistTrackPreview(
          id: track.id,
          title: track.title,
          artist: track.artist,
        );
      }
    }
    return null;
  }

  /// 좋아요 목록이 맨 앞 (실제 저장소와 같다).
  List<Playlist> get _now => [
    Playlist(
      id: Playlist.favoritesId,
      name: '',
      trackCount: members[Playlist.favoritesId]?.length ?? 0,
      featured: _featuredOf(Playlist.favoritesId, null),
      trackIds: {...?members[Playlist.favoritesId]},
    ),
    for (final p in lists)
      Playlist(
        id: p.id,
        name: p.name,
        trackCount: members[p.id]?.length ?? p.trackCount,
        featured: _featuredOf(p.id, p.featured),
        trackIds: {...?members[p.id]},
      ),
  ];

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    yield _now;
    yield* _changes.stream.map((_) => _now);
  }

  List<Track> _tracksOf(String id) => [
    for (final t in members[id] ?? const <String>{})
      if (_tracks[t] != null) _tracks[t]!,
  ];

  @override
  Stream<List<Track>> watchTracks(String playlistId) async* {
    yield _tracksOf(playlistId);
    yield* _changes.stream.map((_) => _tracksOf(playlistId));
  }

  @override
  Future<Playlist> create(String name) async {
    final made = Playlist(id: 'pl${lists.length + 1}', name: name);
    lists.add(made);
    _changes.add(null);
    return made;
  }

  @override
  Future<void> rename(String playlistId, String name) async {
    final i = lists.indexWhere((p) => p.id == playlistId);
    if (i < 0) return;
    final p = lists[i];
    lists[i] = Playlist(
      id: p.id,
      name: name,
      trackCount: p.trackCount,
      featured: p.featured,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete(String playlistId) async {
    lists.removeWhere((p) => p.id == playlistId);
    members.remove(playlistId);
    _changes.add(null);
  }

  @override
  Future<void> addTrack(String trackId, Iterable<String> playlistIds) async {
    for (final id in playlistIds) {
      (members[id] ??= {}).add(trackId);
    }
    _changes.add(null);
  }

  @override
  Future<void> addTracks(Iterable<String> trackIds, String playlistId) async {
    (members[playlistId] ??= {}).addAll(trackIds);
    _changes.add(null);
  }

  @override
  Future<void> removeTrack(String trackId, String playlistId) async {
    members[playlistId]?.remove(trackId);
    _changes.add(null);
  }
}

/// 앱 전체를 띄우는 테스트용 의존성 (DB · 파일 · 권한 없이).
/// 각 기능의 실제 등록을 쓰고 리포지토리만 가짜로 바꾼다.
Future<void> setUpTestDependencies({
  List<Track> tracks = const [],
  DeviceMusicRepository? device,
  CoverRepository? covers,
  CoverColorRepository? coverColors,
  CoverImageSource? imageSource,
  LyricsRepository? lyrics,
  LyricsFileSource? lyricsFile,
  ThemeSettings theme = const ThemeSettings(),
  PlayerStyle playerStyle = PlayerStyle.initial,
  PlayHistoryRepository? history,
  DownloadQueueRepository? downloads,
  DownloaderEngine? engine,
  LinkOpener? linkOpener,
  PreviewPlayer? previewPlayer,
  EngineManager? engineManager,
  AudioPlayerRepository? audio,
  DownloadSettingsRepository? downloadSettings,
  PlaylistRepository? playlists,
  AppLockRepository? appLock,
  AccountRepository? account,
  BiometricAuthenticator? biometric,
  LoadedFolderRepository? folders,
  TrackFileRepository? trackFiles,
  DateTime? joinedAt,
}) async {
  await sl.reset();
  registerTheme(sl);
  registerSecurity(sl);
  registerAccount(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerLyrics(sl);
  registerPlayer(sl);
  registerHome(sl);
  registerPlaylists(sl);
  registerDownloads(sl);
  registerEngine(sl);
  registerSearch(sl);
  registerNotifications(sl);
  registerPermissions(sl);
  sl.allowReassignment = true;
  sl
    ..registerLazySingleton<NotificationSettingsRepository>(
      MemoryNotificationSettings.new,
    )
    ..registerLazySingleton<DownloadNotifier>(FakeDownloadNotifier.new)
    ..registerLazySingleton<PermissionRepository>(FakePermissionRepository.new)
    ..registerLazySingleton<MediaSession>(FakeMediaSession.new)
    ..registerLazySingleton<JoinDateRepository>(
      () => MemoryJoinDate(joinedAt ?? DateTime(2026, 1, 1)),
    )
    ..registerLazySingleton<PlayerStyleRepository>(
      () => MemoryPlayerStyleRepository(playerStyle),
    )
    ..registerLazySingleton<ThemeSettingsRepository>(
      () => MemoryThemeSettingsRepository(theme),
    )
    ..registerLazySingleton<AppLockRepository>(
      () => appLock ?? MemoryAppLockRepository(),
    )
    ..registerLazySingleton<AccountRepository>(
      () => account ?? FakeAccountRepository(),
    )
    ..registerLazySingleton<BiometricAuthenticator>(
      () => biometric ?? FakeBiometricAuthenticator(),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => FakeLibraryRepository(tracks),
    )
    ..registerLazySingleton<LoadedFolderRepository>(
      () => folders ?? MemoryLoadedFolders(),
    )
    ..registerLazySingleton<TrackFileRepository>(
      () => trackFiles ?? FakeTrackFiles(),
    )
    ..registerLazySingleton<DeviceMusicRepository>(
      () => device ?? FakeDeviceMusic(const ScanFound([])),
    )
    ..registerLazySingleton<CoverRepository>(
      () => covers ?? MemoryCoverRepository(),
    )
    ..registerLazySingleton<CoverColorRepository>(
      () => coverColors ?? MemoryCoverColorRepository(),
    )
    ..registerLazySingleton<CoverImageSource>(
      () => imageSource ?? FakeImageSource(),
    )
    ..registerLazySingleton<LyricsRepository>(
      () => lyrics ?? MemoryLyricsRepository(),
    )
    ..registerLazySingleton<LyricsFileSource>(
      () => lyricsFile ?? FakeLyricsFileSource(),
    )
    ..registerLazySingleton<AudioPlayerRepository>(
      () => audio ?? FakeAudioPlayer(),
    )
    ..registerLazySingleton<PlayHistoryRepository>(
      () => history ?? MemoryPlayHistory(),
    )
    ..registerLazySingleton<DownloadSettingsRepository>(
      () => downloadSettings ?? MemoryDownloadSettings(),
    )
    ..registerLazySingleton<EngineManager>(
      () => engineManager ?? FakeEngineManager(),
    )
    ..registerLazySingleton<DownloaderEngine>(
      () => engine ?? FakeDownloaderEngine(),
    )
    ..registerLazySingleton<LinkOpener>(() => linkOpener ?? FakeLinkOpener())
    ..registerLazySingleton<PreviewPlayer>(
      () => previewPlayer ?? FakePreviewPlayer(),
    )
    ..registerLazySingleton<DownloadQueueRepository>(
      () => downloads ?? MemoryDownloadQueue(),
    )
    ..registerLazySingleton<PlaylistRepository>(
      () => playlists ?? MemoryPlaylistRepository(const [], tracks),
    );
  sl.allowReassignment = false;
}

/// 고정된 가입일.
class MemoryJoinDate implements JoinDateRepository {
  const MemoryJoinDate(this.date);

  final DateTime date;

  @override
  Future<DateTime> joinedAt() async => date;
}

/// 재생 엔진 가짜: 불러온 곡 · 재생 상태를 기록하고, 위치 · 곡 끝은 테스트가 흘려보낸다.
class FakeAudioPlayer implements AudioPlayerRepository {
  final _position = StreamController<Duration>.broadcast();
  final _completed = StreamController<void>.broadcast();

  /// 지금 불러온 곡 주소.
  String? loaded;
  bool playing = false;
  Duration? lastSeek;

  /// 불러오기를 실패시킬 주소.
  final failing = <String>{};

  /// 엔진에 한 일의 기록 ('load:uri', 'play', 'pause', 'seek:1000').
  final calls = <String>[];

  void emitPosition(Duration p) => _position.add(p);

  void complete() => _completed.add(null);

  @override
  Stream<Duration> watchPosition() => _position.stream;

  @override
  Stream<void> watchCompleted() => _completed.stream;

  @override
  Future<void> load(String uri) async {
    calls.add('load:$uri');
    if (failing.contains(uri)) throw StateError('cannot load');
    loaded = uri;
    playing = false;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playing = false;
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inMilliseconds}');
    lastSeek = position;
  }
}

/// 로그인 · 내 재생목록을 메모리로 흉내 내는 계정 저장소.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({
    this.support = AccountSupport.available,
    this.account,
    this.playlists = const [],
    this.signInError,
    this.playlistsError,
  });

  @override
  final AccountSupport support;
  GoogleAccount? account;
  final List<PlaylistHit> playlists;
  final AccountException? signInError;
  final AccountException? playlistsError;
  var signIns = 0;

  @override
  Future<GoogleAccount?> restore() async => account;

  @override
  Future<GoogleAccount> signIn() async {
    signIns++;
    final error = signInError;
    if (error != null) throw error;
    return account = const GoogleAccount(
      id: 'u1',
      email: 'me@example.com',
      displayName: '나',
    );
  }

  @override
  Future<void> signOut() async => account = null;

  @override
  Future<List<PlaylistHit>> myPlaylists() async {
    final error = playlistsError;
    if (error != null) throw error;
    if (account == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    return playlists;
  }
}

/// 정해 둔 답을 돌려주는 엔진. [error]가 있으면 그것을 던진다.
class FakeDownloaderEngine implements DownloaderEngine {
  FakeDownloaderEngine({
    this.pages = const [SearchPage(items: [], hasNext: false)],
    this.info,
    this.infoByUrl = const {},
    this.channel,
    this.error,
    this.streamFailure,
    this.streamGate,
    this.playlistPage = const PlaylistSearchPage(items: [], hasNext: false),
  });

  /// [searchPlaylists]가 돌려줄 결과와 받은 검색어들.
  final PlaylistSearchPage playlistPage;
  final playlistSearches = <String>[];

  /// 쪽 번호 순서대로 돌려줄 검색 결과.
  final List<SearchPage> pages;
  final MediaInfo? info;

  /// 주소별로 따로 돌려줄 곡 정보 (없으면 [info], 그것도 없으면 못 찾음).
  final Map<String, MediaInfo> infoByUrl;

  /// [fetchChannel]이 돌려줄 채널 정보 (없으면 `unavailable`).
  final ChannelInfo? channel;
  final Object? error;
  final searches = <(String, SearchSource, int)>[];

  /// 검색마다 최신순으로 찾았는지.
  final newestFlags = <bool>[];
  final infos = <String>[];
  final channels = <String>[];

  /// [resolveAudioStream]을 부를 때마다 새로 읽으라고 했는지.
  final refreshFlags = <bool>[];

  /// [resolveAudioStream]에 넘어온 곡 주소들.
  final streams = <String>[];

  /// 스트림 주소 조회를 실패시킬 까닭 (없으면 성공).
  final EngineFailure? streamFailure;

  /// 스트림 주소 조회가 끝나길 기다리게 하려면 넣는다 (느린 yt-dlp 흉내).
  final Future<void>? streamGate;

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
    bool newest = false,
  }) async {
    searches.add((query, source, page));
    newestFlags.add(newest);
    if (error != null) throw error!;
    return page < pages.length ? pages[page] : pages.last;
  }

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    playlistSearches.add(query);
    if (error != null) throw error!;
    return playlistPage;
  }

  @override
  Future<MediaInfo> fetchInfo(String url) async {
    infos.add(url);
    if (error != null) throw error!;
    final found = infoByUrl[url] ?? info;
    if (found == null) throw const EngineException(EngineFailure.notFound);
    return found;
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    channels.add(url);
    final found = channel;
    if (found == null) throw const EngineException(EngineFailure.unavailable);
    return found;
  }

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
  }) async {
    streams.add(url);
    refreshFlags.add(refresh);
    await streamGate;
    final failure = streamFailure;
    if (failure != null) throw EngineException(failure);
    return AudioStream(url: 'https://stream.test/$url');
  }
}

/// 연 주소를 기록하는 링크 열기. [opens]가 false면 열지 못한 것처럼 답한다.
class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.opens = true});

  final bool opens;
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return opens;
  }
}

/// 설치 여부만 흉내 내는 엔진 관리자. [installed]가 false면 [install]로 설치된다.
class FakeEngineManager implements EngineManager {
  FakeEngineManager({
    this.supported = true,
    this.installed = false,
    this.failInstall = false,
  });

  final bool supported;
  bool installed;
  final bool failInstall;
  int installs = 0;

  @override
  Future<EngineStatus> status() async => EngineStatus(
    supported: supported,
    installed: installed,
    version: installed ? '2026.01.01' : null,
    managed: installed,
  );

  @override
  Future<EngineStatus> install() async {
    installs++;
    if (failInstall) throw Exception('fail');
    installed = true;
    return status();
  }
}

/// 미리 듣기 플레이어 가짜: 재생한 주소와 멈춘 횟수를 기록하고, 곡 끝은 테스트가 흘려보낸다.
class FakePreviewPlayer implements PreviewPlayer {
  FakePreviewPlayer({this.failure});

  /// 재생 시작을 실패시킬 까닭 (없으면 성공).
  final EngineFailure? failure;
  final _completed = StreamController<void>.broadcast();
  final _progress = StreamController<PreviewProgress>.broadcast();
  final _failures = StreamController<String>.broadcast();

  /// 재생을 시작한 스트림 주소 순서.
  final played = <String>[];
  int stops = 0;

  /// 지금 소리가 나고 있는지.
  bool playing = false;

  void complete() => _completed.add(null);

  void progress(Duration position, Duration? duration) =>
      _progress.add(PreviewProgress(position: position, duration: duration));

  @override
  Future<void> play(AudioStream stream) async {
    final f = failure;
    if (f != null) throw EngineException(f);
    played.add(stream.url);
    playing = true;
  }

  /// 옮긴 위치 순서.
  final seeks = <Duration>[];

  @override
  Future<void> seek(Duration position) async => seeks.add(position);

  int pauses = 0;
  int resumes = 0;

  @override
  Future<void> pause() async {
    pauses++;
    playing = false;
  }

  @override
  Future<void> resume() async {
    resumes++;
    playing = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    playing = false;
  }

  @override
  Stream<void> watchCompleted() => _completed.stream;

  void fail(String reason) => _failures.add(reason);

  @override
  Stream<String> watchFailures() => _failures.stream;

  @override
  Stream<PreviewProgress> watchProgress() => _progress.stream;
}

/// 메모리 알림 설정.
class MemoryNotificationSettings implements NotificationSettingsRepository {
  NotificationSettings settings = const NotificationSettings();
  bool granted = true;

  @override
  Future<NotificationSettings> load() async => settings;

  @override
  Future<void> save(NotificationSettings s) async => settings = s;

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> openSystemSettings() async {}
}

/// 받기 결과 알림 기록 ('done:id', 'failed:id', 'clearResults').
class FakeDownloadNotifier implements DownloadNotifier {
  final calls = <String>[];

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
  }) async => calls.add('${failed ? 'failed' : 'done'}:$id');

  @override
  Future<void> clearResults() async => calls.add('clearResults');
}

/// 재생 알림 가짜: 받은 상태를 기록하고, 알림 조작은 테스트가 흘려보낸다.
class FakeMediaSession implements MediaSession {
  final _commands = StreamController<MediaCommand>.broadcast();
  final updates = <MediaSessionInfo?>[];

  void press(MediaCommand c) => _commands.add(c);

  @override
  Stream<MediaCommand> watchCommands() => _commands.stream;

  @override
  Future<void> update(MediaSessionInfo? info) async => updates.add(info);
}

class FakePermissionRepository implements PermissionRepository {
  final levels = <AppPermission, PermissionLevel>{
    for (final p in AppPermission.values) p: PermissionLevel.denied,
  };
  int openedSettings = 0;

  @override
  List<AppPermission> get supported => AppPermission.values;

  @override
  Future<PermissionLevel> status(AppPermission permission) async =>
      levels[permission]!;

  @override
  Future<PermissionLevel> request(AppPermission permission) async =>
      levels[permission] = PermissionLevel.granted;

  @override
  Future<void> openSystemSettings() async => openedSettings++;
}
