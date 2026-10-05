import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/lyrics/di.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:music_download_play_app/features/covers/domain/repositories/cover_repository.dart';
import 'package:music_download_play_app/features/downloads/di.dart';
import 'package:music_download_play_app/features/engine/di.dart';
import 'package:music_download_play_app/features/engine/domain/entities/engine_status.dart';
import 'package:music_download_play_app/features/engine/domain/repositories/engine_manager.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
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
import 'package:music_download_play_app/features/player/di.dart';
import 'package:music_download_play_app/features/player/domain/entities/player_style.dart';
import 'package:music_download_play_app/features/player/domain/repositories/audio_player_repository.dart';
import 'package:music_download_play_app/features/player/domain/repositories/player_style_repository.dart';
import 'package:music_download_play_app/features/playlists/di.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_download_play_app/features/search/di.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_source.dart';
import 'package:music_download_play_app/features/search/domain/repositories/downloader_engine.dart';
import 'package:music_download_play_app/features/search/domain/repositories/link_opener.dart';
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

/// 파일 복사 없이 경로만 기억하는 커버 저장소.
class MemoryCoverRepository implements CoverRepository {
  final saved = <String, String>{};

  @override
  Future<Map<String, String>> loadAll() async => {...saved};

  @override
  Future<String> save(String key, String sourcePath) async =>
      saved[key] = sourcePath;

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

/// 메모리 다운로드 설정 저장소. [picked]는 폴더 선택기가 고를 경로 (null이면 취소).
class MemoryDownloadSettings implements DownloadSettingsRepository {
  MemoryDownloadSettings({this.path = '/music/Mulo', this.picked});

  String path;
  String? picked;

  @override
  Future<String> loadSavePath() async => path;

  @override
  Future<void> saveSavePath(String value) async => path = value;

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
  Future<void> recordPlay(PlayRecord record) async {
    plays.add(record);
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
  Future<void> pause(String id) async => controls.add('pause:$id');

  @override
  Future<void> resume(String id) async => controls.add('resume:$id');

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
  EngineManager? engineManager,
  AudioPlayerRepository? audio,
  DownloadSettingsRepository? downloadSettings,
  PlaylistRepository? playlists,
  AppLockRepository? appLock,
  BiometricAuthenticator? biometric,
  LoadedFolderRepository? folders,
  TrackFileRepository? trackFiles,
  DateTime? joinedAt,
}) async {
  await sl.reset();
  registerTheme(sl);
  registerSecurity(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerLyrics(sl);
  registerPlayer(sl);
  registerHome(sl);
  registerPlaylists(sl);
  registerDownloads(sl);
  registerEngine(sl);
  registerSearch(sl);
  sl.allowReassignment = true;
  sl
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

/// 정해 둔 답을 돌려주는 엔진. [error]가 있으면 그것을 던진다.
class FakeDownloaderEngine implements DownloaderEngine {
  FakeDownloaderEngine({
    this.pages = const [SearchPage(items: [], hasNext: false)],
    this.info,
    this.infoByUrl = const {},
    this.channel,
    this.error,
  });

  /// 쪽 번호 순서대로 돌려줄 검색 결과.
  final List<SearchPage> pages;
  final MediaInfo? info;

  /// 주소별로 따로 돌려줄 곡 정보 (없으면 [info], 그것도 없으면 못 찾음).
  final Map<String, MediaInfo> infoByUrl;

  /// [fetchChannel]이 돌려줄 채널 정보 (없으면 `unavailable`).
  final ChannelInfo? channel;
  final Object? error;
  final searches = <(String, SearchSource, int)>[];
  final infos = <String>[];
  final channels = <String>[];

  @override
  Future<SearchPage> search(
    String query, {
    SearchSource source = SearchSource.youtube,
    int page = 0,
    int size = 20,
  }) async {
    searches.add((query, source, page));
    if (error != null) throw error!;
    return page < pages.length ? pages[page] : pages.last;
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
