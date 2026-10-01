import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/lyrics/di.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:music_download_play_app/features/covers/domain/repositories/cover_repository.dart';
import 'package:music_download_play_app/features/downloads/di.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';
import 'package:music_download_play_app/features/downloads/domain/repositories/download_queue_repository.dart';
import 'package:music_download_play_app/features/home/di.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/repositories/play_history_repository.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/entities/track_info.dart';
import 'package:music_download_play_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_download_play_app/features/player/di.dart';
import 'package:music_download_play_app/features/playlists/di.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/domain/repositories/playlist_repository.dart';
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
  MemoryPlaylistRepository([List<Playlist> initial = const []])
    : lists = [...initial];

  final List<Playlist> lists;

  /// 재생목록 id → 들어 있는 곡 id.
  final members = <String, Set<String>>{};

  /// 재생목록 id → 고른 카드 색.
  final colors = <String, int?>{};
  final _changes = StreamController<List<Playlist>>.broadcast();

  List<Playlist> get _now => [
    for (final p in lists)
      Playlist(
        id: p.id,
        name: p.name,
        trackCount: members[p.id]?.length ?? p.trackCount,
        colorIndex: colors.containsKey(p.id) ? colors[p.id] : p.colorIndex,
        topTracks: p.topTracks,
        topArtists: p.topArtists,
      ),
  ];

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    yield _now;
    yield* _changes.stream;
  }

  @override
  Future<Playlist> create(String name) async {
    final made = Playlist(id: 'pl${lists.length + 1}', name: name);
    lists.add(made);
    _changes.add(_now);
    return made;
  }

  @override
  Future<void> addTrack(String trackId, Iterable<String> playlistIds) async {
    for (final id in playlistIds) {
      (members[id] ??= {}).add(trackId);
    }
    _changes.add(_now);
  }

  @override
  Future<void> removeTrack(String trackId, String playlistId) async {
    members[playlistId]?.remove(trackId);
    _changes.add(_now);
  }

  @override
  Future<void> setColor(String playlistId, int? colorIndex) async {
    colors[playlistId] = colorIndex;
    _changes.add(_now);
  }
}

/// 앱 전체를 띄우는 테스트용 의존성 (DB · 파일 · 권한 없이).
/// 각 기능의 실제 등록을 쓰고 리포지토리만 가짜로 바꾼다.
Future<void> setUpTestDependencies({
  List<Track> tracks = const [],
  DeviceMusicRepository? device,
  CoverRepository? covers,
  CoverImageSource? imageSource,
  LyricsRepository? lyrics,
  LyricsFileSource? lyricsFile,
  ThemeSettings theme = const ThemeSettings(),
  PlayHistoryRepository? history,
  DownloadQueueRepository? downloads,
  PlaylistRepository? playlists,
  AppLockRepository? appLock,
  BiometricAuthenticator? biometric,
  LoadedFolderRepository? folders,
  TrackFileRepository? trackFiles,
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
  sl.allowReassignment = true;
  sl
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
    ..registerLazySingleton<CoverImageSource>(
      () => imageSource ?? FakeImageSource(),
    )
    ..registerLazySingleton<LyricsRepository>(
      () => lyrics ?? MemoryLyricsRepository(),
    )
    ..registerLazySingleton<LyricsFileSource>(
      () => lyricsFile ?? FakeLyricsFileSource(),
    )
    ..registerLazySingleton<PlayHistoryRepository>(
      () => history ?? MemoryPlayHistory(),
    )
    ..registerLazySingleton<DownloadQueueRepository>(
      () => downloads ?? MemoryDownloadQueue(),
    )
    ..registerLazySingleton<PlaylistRepository>(
      () => playlists ?? MemoryPlaylistRepository(),
    );
  sl.allowReassignment = false;
}
