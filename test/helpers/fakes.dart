import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/account/di.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';
import 'package:music_download_play_app/features/account/domain/repositories/account_repository.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/lyrics/di.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics_settings.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_settings_repository.dart';
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
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';
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
import 'package:music_download_play_app/features/player/domain/entities/playback_snapshot.dart';
import 'package:music_download_play_app/features/player/domain/repositories/audio_player_repository.dart';
import 'package:music_download_play_app/features/equalizer/di.dart';
import 'package:music_download_play_app/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:music_download_play_app/features/equalizer/domain/repositories/equalizer_repository.dart';
import 'package:music_download_play_app/features/player/domain/repositories/mix_with_others_repository.dart';
import 'package:music_download_play_app/features/player/domain/repositories/playback_speed_repository.dart';
import 'package:music_download_play_app/features/player/domain/entities/output_behavior.dart';
import 'package:music_download_play_app/features/player/domain/repositories/output_behavior_repository.dart';
import 'package:music_download_play_app/features/player/domain/repositories/player_style_repository.dart';
import 'package:music_download_play_app/features/playlists/di.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_download_play_app/features/search/di.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_language.dart';
import 'package:music_download_play_app/features/search/domain/entities/audio_stream.dart';
import 'package:music_download_play_app/features/search/domain/entities/preview_progress.dart';
import 'package:music_download_play_app/features/search/domain/entities/preview_snapshot.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/search_source.dart';
import 'package:music_download_play_app/features/search/domain/entities/subtitle_track.dart';
import 'package:music_download_play_app/features/search/domain/repositories/downloader_engine.dart';
import 'package:music_download_play_app/features/search/domain/repositories/link_opener.dart';
import 'package:music_download_play_app/features/search/domain/repositories/preview_player.dart';
import 'package:music_download_play_app/features/security/di.dart';
import 'package:music_download_play_app/features/security/domain/entities/app_lock_settings.dart';
import 'package:music_download_play_app/features/security/domain/repositories/app_lock_repository.dart';
import 'package:music_download_play_app/features/subscriptions/di.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/background_status.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_hit.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/feed_video.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/new_video_download_request.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/subscribed_channel.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/subscription_settings.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/background_checker.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/channel_feed.dart';
import 'package:music_download_play_app/features/subscriptions/domain/repositories/subscription_repository.dart';
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
  Future<int> hiddenCount() async => 0;

  @override
  Future<int> purgeHidden() async => 0;

  @override
  Future<void> hide(String trackId) async {
    _tracks.removeWhere((t) => t.id == trackId);
    _changes.add(_sorted);
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

  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> watchChanges() => _changes.stream;

  /// 저장 위치 목록 (null이면 아직 따로 저장한 적 없음).
  List<String>? saveLocations;

  @override
  String get defaultFolder => '/music/default';

  @override
  Future<List<String>> loadExtra() async => [...extra];

  @override
  Future<void> saveExtra(List<String> folders) async {
    extra = [...folders];
    _changes.add(null);
  }

  @override
  Future<List<String>?> loadSaveLocations() async =>
      saveLocations == null ? null : [...saveLocations!];

  @override
  Future<void> saveSaveLocations(List<String> folders) async =>
      saveLocations = [...folders];

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

/// 곡 uri별로 미리 정한 내장 커버 경로를 돌려주는 가짜 (없으면 null).
class FakeEmbeddedCovers implements EmbeddedCoverRepository {
  FakeEmbeddedCovers([this.byUri = const {}]);

  final Map<String, String> byUri;
  final extracted = <String>[];
  final discarded = <String>[];

  @override
  Future<String?> extract(Track track) async {
    extracted.add(track.uri);
    return byUri[track.uri];
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
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

  AudioFormat format = AudioFormat.opus;

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
class MemoryLyricsSettingsRepository implements LyricsSettingsRepository {
  MemoryLyricsSettingsRepository([
    this.settings = const LyricsSettings(latencyMs: 0),
  ]);

  LyricsSettings settings;

  @override
  Future<LyricsSettings> load() async => settings;

  @override
  Future<void> saveLatency(int milliseconds) async =>
      settings = settings.copyWith(latencyMs: milliseconds);

  @override
  Future<void> saveTheme(LyricsTheme theme) async =>
      settings = settings.copyWith(theme: theme);

  @override
  Future<void> saveCoverBackground(bool on) async =>
      settings = settings.copyWith(coverBackground: on);

  @override
  Future<void> saveOverlay(bool on) async =>
      settings = settings.copyWith(overlay: on);
}

class MemoryPlayerStyleRepository implements PlayerStyleRepository {
  MemoryPlayerStyleRepository([this.style = PlayerStyle.initial]);

  PlayerStyle style;

  @override
  Future<PlayerStyle> load() async => style;

  @override
  Future<void> save(PlayerStyle value) async => style = value;
}

class MemoryMixWithOthersRepository implements MixWithOthersRepository {
  bool value = false;

  @override
  Future<bool> load() async => value;

  @override
  Future<void> save(bool v) async => value = v;

  @override
  Future<void> apply(bool v) async {}
}

class MemoryPlaybackSpeedRepository implements PlaybackSpeedRepository {
  double value = 1;

  @override
  Future<double> load() async => value;

  @override
  Future<void> save(double v) async => value = v;

  @override
  Future<void> apply(double v) async {}
}

class MemoryOutputBehaviorRepository implements OutputBehaviorRepository {
  OutputBehavior value = const OutputBehavior();

  @override
  Future<OutputBehavior> load() async => value;

  @override
  Future<void> save(OutputBehavior v) async => value = v;

  @override
  Future<void> apply(OutputBehavior v) async {}
}

class MemoryEqualizerRepository implements EqualizerRepository {
  MemoryEqualizerRepository({
    this.info,
    this.settings = const EqualizerSettings(),
  });

  final EqualizerInfo? info;
  EqualizerSettings settings;
  EqualizerSettings? applied;

  @override
  Future<EqualizerSetup> load() async =>
      EqualizerSetup(info: info, settings: settings);

  @override
  Future<void> apply(EqualizerSettings s) async => applied = s;

  @override
  Future<void> save(EqualizerSettings s) async => settings = s;

  @override
  Future<void> setDeviceProfile(bool enabled, EqualizerSettings s) async {}

  @override
  Stream<void> watchDevice() => const Stream.empty();

  @override
  Future<EqualizerSetup> loadForDevice(String deviceKey) => load();

  @override
  Future<void> saveForDevice(String deviceKey, EqualizerSettings s) async =>
      settings = s;

  final List<EqualizerUserPreset> userPresets = [];

  @override
  Future<List<EqualizerUserPreset>> presets() async => [...userPresets];

  @override
  Future<void> savePreset(EqualizerUserPreset preset) async {
    userPresets.removeWhere((p) => p.id == preset.id);
    userPresets.add(preset);
  }

  @override
  Future<void> deletePreset(String id) async =>
      userPresets.removeWhere((p) => p.id == id);

  @override
  Future<List<EqualizerDevice>> devices() async => const [];

  @override
  Future<void> assignPreset(String deviceKey, String? presetId) async {}
}

class MemoryThemeSettingsRepository implements ThemeSettingsRepository {
  MemoryThemeSettingsRepository([this.settings = const ThemeSettings()]);

  ThemeSettings settings;

  @override
  Future<ThemeSettings> load() async => settings;

  @override
  Future<void> savePreset(String presetId) async => settings = ThemeSettings(
    presetId: presetId,
    mode: settings.mode,
    followMood: settings.followMood,
  );

  @override
  Future<void> saveMode(AppThemeMode mode) async => settings = ThemeSettings(
    presetId: settings.presetId,
    mode: mode,
    followMood: settings.followMood,
  );

  @override
  Future<void> saveFollowMood(bool value) async => settings = ThemeSettings(
    presetId: settings.presetId,
    mode: settings.mode,
    followMood: value,
  );
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

  /// 이미 받은 곡의 원본 주소 키 (`downloadSourceKey`).
  final downloadedKeys = <String>{};

  /// 받기 요청 기록.
  final requests = <DownloadRequest>[];

  /// 원본 주소 → 이미 받은 곡 · 받는 중 (재생목록 가져오기 건너뛰기 시험용).
  final existing = <String, ExistingDownload>{};

  @override
  Future<ExistingDownload> findExisting(String url) async =>
      existing[url] ?? ExistingDownload.none;

  @override
  Stream<Set<String>> watchDownloadedKeys() => Stream.value(downloadedKeys);

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

  @override
  Future<void> reorder(List<String> playlistIds) async {
    final byId = {for (final p in lists) p.id: p};
    final next = [
      for (final id in playlistIds) ?byId.remove(id),
      ...byId.values,
    ];
    lists
      ..clear()
      ..addAll(next);
    _changes.add(null);
  }
}

/// 앱 전체를 띄우는 테스트용 의존성 (DB · 파일 · 권한 없이).
/// 각 기능의 실제 등록을 쓰고 리포지토리만 가짜로 바꾼다.
/// 파일 태그 쓰기 가짜. 기본은 태그를 쓰지 않는 곡(DB만 고친다).
class FakeTrackTagRepository implements TrackTagRepository {
  FakeTrackTagRepository([this.result = TagWriteResult.unsupported]);

  TagWriteResult result;

  @override
  Future<TagWriteResult> write(
    Track track, {
    CoverArt? cover,
    int? color,
  }) async => result;

  @override
  String? get lastFailure => null;

  /// 가사 태그에 쓰라고 한 글 (곡 id → 글).
  final lyricsWritten = <String, String>{};

  @override
  Future<TagWriteResult> writeLyrics(Track track, String lyrics) async {
    lyricsWritten[track.id] = lyrics;
    return result;
  }
}

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
  TrackTagRepository? trackTags,
  DateTime? joinedAt,
  SubscriptionRepository? subscriptions,
  ChannelFeed? channelFeed,
}) async {
  await sl.reset();
  registerTheme(sl);
  registerSecurity(sl);
  registerAccount(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerLyrics(sl);
  registerPlayer(sl);
  registerEqualizer(sl);
  registerHome(sl);
  registerPlaylists(sl);
  registerDownloads(sl);
  registerEngine(sl);
  registerSearch(sl);
  registerNotifications(sl);
  registerPermissions(sl);
  registerSubscriptions(sl);
  sl.allowReassignment = true;
  sl
    ..registerLazySingleton<TrackTagRepository>(
      () => trackTags ?? FakeTrackTagRepository(),
    )
    ..registerLazySingleton<SubscriptionRepository>(
      () => subscriptions ?? MemorySubscriptionRepository(),
    )
    ..registerLazySingleton<ChannelFeed>(() => channelFeed ?? FakeChannelFeed())
    ..registerLazySingleton<BackgroundChecker>(FakeBackgroundChecker.new)
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
    ..registerLazySingleton<LyricsSettingsRepository>(
      MemoryLyricsSettingsRepository.new,
    )
    ..registerLazySingleton<MixWithOthersRepository>(
      MemoryMixWithOthersRepository.new,
    )
    ..registerLazySingleton<PlaybackSpeedRepository>(
      MemoryPlaybackSpeedRepository.new,
    )
    ..registerLazySingleton<OutputBehaviorRepository>(
      MemoryOutputBehaviorRepository.new,
    )
    ..registerLazySingleton<EqualizerRepository>(MemoryEqualizerRepository.new)
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

/// 재생 엔진 가짜: 받은 대기열 · 재생 상태를 기록하고, 위치 · 곡 넘김 · 끝은 테스트가 흘려보낸다.
class FakeAudioPlayer implements AudioPlayerRepository {
  final _position = StreamController<Duration>.broadcast();
  final _track = StreamController<PlaybackTrackChange>.broadcast();
  final _ended = StreamController<void>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _openPlayer = StreamController<void>.broadcast();

  /// 마지막으로 받은 대기열 스냅샷.
  PlaybackSnapshot? snapshot;

  /// 엔진이 지금 보고 있는 곡 번호.
  var index = 0;

  /// 지금 불러온 곡 주소.
  String? loaded;
  bool playing = false;
  Duration? lastSeek;

  /// 불러오기를 실패시킬 주소.
  final failing = <String>{};

  /// 엔진에 한 일의 기록 ('queue:uri', 'skip:1', 'play', 'pause', 'seek:1000').
  final calls = <String>[];

  /// [restore]가 돌려줄 대기열 (앱을 다시 켠 상황).
  PlaybackSnapshot? restoreSnapshot;

  /// [takeOpenPlayerRequest]가 돌려줄 값 (알림을 눌러 앱이 새로 켜진 상황).
  var openPlayerRequested = false;

  void emitPosition(Duration p) => _position.add(p);

  /// 엔진이 스스로 다음 곡으로 넘어갔다고 알린다 (곡 끝, 알림의 다음 버튼).
  void emitTrack(int i) {
    index = i;
    final item = snapshot!.items[i];
    loaded = item.uri;
    _track.add(PlaybackTrackChange(i, item.id));
  }

  /// 반복 없이 대기열 끝까지 들었다고 알린다.
  void end() {
    playing = false;
    _ended.add(null);
  }

  /// 알림을 눌렀다고 알린다 (앱이 켜져 있는 중).
  void emitOpenPlayer() => _openPlayer.add(null);

  /// 엔진이 스스로 재생 상태를 바꿨다고 알린다 (다른 앱에 오디오 포커스를 뺏김 등).
  void emitPlaying(bool value) {
    playing = value;
    _playing.add(value);
  }

  @override
  Stream<bool> watchPlaying() => _playing.stream;

  @override
  Stream<Duration> watchPosition() => _position.stream;

  @override
  Stream<PlaybackTrackChange> watchTrackChange() => _track.stream;

  @override
  Stream<void> watchEnded() => _ended.stream;

  @override
  Stream<void> watchOpenPlayer() => _openPlayer.stream;

  @override
  Future<void> setQueue(PlaybackSnapshot s) async {
    final current = s.current;
    calls.add('queue:${current?.uri}');
    snapshot = s;
    index = s.index;
    if (current == null) {
      loaded = null;
      playing = false;
      return;
    }
    if (failing.contains(current.uri)) throw StateError('cannot load');
    loaded = current.uri;
    playing = s.playing;
    if (s.position != null) lastSeek = s.position;
  }

  @override
  Future<void> setLoop(Duration? start, Duration? end) async {
    calls.add(
      start == null || end == null
          ? 'loop:off'
          : 'loop:${start.inMilliseconds}-${end.inMilliseconds}',
    );
  }

  @override
  Future<void> skipTo(int i) async {
    calls.add('skip:$i');
    index = i;
    loaded = snapshot!.items[i].uri;
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

  @override
  Future<PlaybackSnapshot?> restore() async => restoreSnapshot;

  @override
  Future<bool> takeOpenPlayerRequest() async {
    final requested = openPlayerRequested;
    openPlayerRequested = false;
    return requested;
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
    this.subscriptions = const [],
    this.channelPlaylistsById = const {},
  });

  @override
  final AccountSupport support;
  GoogleAccount? account;
  final List<PlaylistHit> playlists;
  final List<ChannelHit> subscriptions;
  final Map<String, List<PlaylistHit>> channelPlaylistsById;
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

  @override
  Future<List<ChannelHit>> mySubscriptions({
    void Function(int loaded)? onProgress,
  }) async {
    final error = playlistsError;
    if (error != null) throw error;
    if (account == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    onProgress?.call(subscriptions.length);
    return subscriptions;
  }

  @override
  Future<List<PlaylistHit>> channelPlaylists(String channelId) async {
    final error = playlistsError;
    if (error != null) throw error;
    if (account == null) {
      throw const AccountException(AccountFailure.unauthorized);
    }
    return channelPlaylistsById[channelId] ?? const [];
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

  /// [resolveAudioStream]에 넘어온 오디오 언어들.
  final audioLanguageArgs = <String?>[];

  /// [fetchAudioLanguages]가 돌려줄 오디오 언어 트랙들.
  List<AudioLanguage> audioLanguages = const [];

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

  /// [fetchSubtitles]가 돌려줄 자막 (없으면 자막 없음)과 받은 주소들.
  SubtitleTrack? subtitles;
  final subtitleUrls = <String>[];

  @override
  Future<SubtitleTrack?> fetchSubtitles(
    String url, {
    List<String> preferLanguages = const ['ko', 'en'],
  }) async {
    subtitleUrls.add(url);
    return subtitles;
  }

  @override
  Future<ChannelInfo> fetchChannel(String url) async {
    channels.add(url);
    final found = channel;
    if (found == null) throw const EngineException(EngineFailure.unavailable);
    return found;
  }

  @override
  Future<List<AudioLanguage>> fetchAudioLanguages(String url) async =>
      audioLanguages;

  @override
  Future<AudioStream> resolveAudioStream(
    String url, {
    bool refresh = false,
    String? audioLanguage,
  }) async {
    streams.add(url);
    refreshFlags.add(refresh);
    audioLanguageArgs.add(audioLanguage);
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
    this.updated = false,
    this.failRevert = false,
    this.bundledOnly = false,
  });

  final bool supported;
  bool installed;
  final bool failInstall;

  /// 업데이트한 yt-dlp가 있는지 (있으면 번들 버전으로 되돌릴 수 있다).
  bool updated;
  final bool failRevert;

  /// 번들 yt-dlp만 쓰는 중 (Android): 지울 것이 없다. 업데이트한 것을 지우면 이 상태가 된다.
  bool bundledOnly;
  int installs = 0;

  @override
  Future<EngineStatus> status() async => EngineStatus(
    supported: supported,
    installed: installed,
    version: installed && !bundledOnly ? '2026.01.01' : null,
    managed: installed,
    removable: installed && supported && !bundledOnly,
    revertible: updated,
  );

  int removes = 0;

  @override
  Future<EngineStatus> remove() async {
    removes++;
    if (failRevert) throw Exception('fail');
    // 업데이트한 yt-dlp를 지우면 번들 버전으로 돌아가 계속 쓸 수 있다 (Android).
    if (updated) {
      updated = false;
      bundledOnly = true;
    } else {
      installed = false;
    }
    return status();
  }

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

  /// 플레이어에 적어 둔 곡 (재생 시작 뒤에 Cubit이 남긴다).
  final remembered = <MediaHit>[];

  /// [current]가 돌려줄 값. 앱이 꺼졌다 켜진 뒤 플레이어에 남은 소리를 흉내 낸다.
  PreviewSnapshot? snapshot;

  @override
  Future<void> remember(MediaHit hit) async => remembered.add(hit);

  @override
  Future<PreviewSnapshot?> current() async => snapshot;

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

/// 받기 알림 기록 ('progress:제목:42', 'clear', 'done:id', 'failed:id').
class FakeDownloadNotifier implements DownloadNotifier {
  final calls = <String>[];

  /// 결과 알림에 담긴 곡 이미지 (알림 id → 주소).
  final resultArt = <String, String?>{};

  /// 마지막 진행 알림의 내용 (제목 · 본문 · 머리말 · 앞에 붙들기 · 미리 듣기 버튼).
  final shown = <Map<String, Object?>>[];
  final _actions = StreamController<DownloadNotificationAction>.broadcast();

  void press(DownloadNotificationAction a) => _actions.add(a);

  @override
  Stream<DownloadNotificationAction> watchActions() => _actions.stream;

  final _opens = StreamController<String>.broadcast();

  /// 알림 본문을 눌러 앱이 이미 떠 있는 채로 열린 것처럼 한다.
  void pressBody(String id) => _opens.add(id);

  @override
  Stream<String> watchOpenRequests() => _opens.stream;

  /// 알림을 눌러 새로 켜진 것처럼 줄 id (한 번 받으면 비운다).
  String? launchedWith;

  @override
  Future<String?> takeOpenRequest() async {
    final id = launchedWith;
    launchedWith = null;
    return id;
  }

  @override
  Future<void> showProgress({
    required String title,
    required String body,
    int? percent,
    bool foreground = true,
    String? subText,
    String? previewLabel,
    String? cancelLabel,
    String? holdLabel,
    String? pauseLabel,
    String? stopLabel,
    String? openId,
    String? artUri,
  }) async {
    shown.add({
      'title': title,
      'body': body,
      'subText': subText,
      'foreground': foreground,
      'preview': previewLabel,
      'cancel': cancelLabel,
      'hold': holdLabel,
      'pause': pauseLabel,
      'stop': stopLabel,
      'openId': openId,
      'artUri': artUri,
    });
    calls.add('progress:$title:$percent');
  }

  @override
  Future<void> clearProgress() async => calls.add('clear');

  @override
  Future<void> showResult({
    required String id,
    required String title,
    required String body,
    required bool failed,
    String? artUri,
  }) async {
    resultArt[id] = artUri;
    calls.add('${failed ? 'failed' : 'done'}:$id');
  }

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

  Map<String, String> queueArt = const {};

  @override
  Future<void> updateQueueArt(Map<String, String> artById) async =>
      queueArt = artById;
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

/// 메모리 구독 저장소.
class MemorySubscriptionRepository implements SubscriptionRepository {
  MemorySubscriptionRepository({
    List<SubscribedChannel> channels = const [],
    this.settings = const SubscriptionSettings(),
  }) : channels = [...channels];

  List<SubscribedChannel> channels;
  SubscriptionSettings settings;

  @override
  Future<List<SubscribedChannel>> loadChannels() async => [...channels];

  @override
  Future<void> saveChannels(List<SubscribedChannel> value) async =>
      channels = [...value];

  @override
  Future<SubscriptionSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(SubscriptionSettings value) async =>
      settings = value;

  Set<String> seenVideos = {};

  @override
  Future<Set<String>> loadSeenVideos() async => {...seenVideos};

  @override
  Future<void> saveSeenVideos(Set<String> ids) async => seenVideos = {...ids};
}

/// 채널 id별로 정해 둔 피드를 돌려주는 가짜 채널 피드.
class FakeChannelFeed implements ChannelFeed {
  FakeChannelFeed({this.feeds = const {}, this.failing = const {}});

  final Map<String, List<FeedVideo>> feeds;

  /// 읽을 때 실패하는 채널 id.
  final Set<String> failing;

  @override
  Future<String?> resolveChannelId(String channelUrl) async {
    final m = RegExp(r'/channel/(UC[0-9A-Za-z_-]{22})').firstMatch(channelUrl);
    return m?.group(1);
  }

  @override
  Future<List<FeedVideo>> fetch(String channelId) async {
    if (failing.contains(channelId)) throw StateError('feed failed');
    return feeds[channelId] ?? const [];
  }
}

/// 마지막으로 받은 동기화 내용을 기록하는 가짜 백그라운드 확인.
class FakeBackgroundChecker implements BackgroundChecker {
  List<SubscribedChannel>? lastChannels;
  SubscriptionSettings? lastSettings;
  var cleared = 0;
  var openRequested = false;

  @override
  Future<void> sync(
    List<SubscribedChannel> channels,
    SubscriptionSettings settings,
    BackgroundTexts texts,
  ) async {
    lastChannels = channels;
    lastSettings = settings;
  }

  @override
  Future<bool> takeOpenRequest() async {
    final v = openRequested;
    openRequested = false;
    return v;
  }

  @override
  Stream<void> watchOpenRequests() => const Stream.empty();

  @override
  Future<void> clearNotification() async => cleared++;

  var movedToBack = 0;
  final downloadRequests = <NewVideoDownloadRequest>[];

  @override
  Future<List<NewVideoDownloadRequest>> takeDownloadRequests() async => [
    ...downloadRequests,
  ];

  @override
  Stream<NewVideoDownloadRequest> watchDownloadRequests() =>
      const Stream.empty();

  @override
  Future<void> moveAppToBack() async => movedToBack++;

  var checkedNow = 0;
  BackgroundStatus? statusValue;

  /// 지금 확인을 돌린 뒤 보이는 상태 (마지막 확인 시각이 바뀐 것처럼).
  BackgroundStatus? statusAfterCheck;

  @override
  Future<void> checkNow() async {
    checkedNow++;
    statusValue = statusAfterCheck ?? statusValue;
  }

  @override
  Future<BackgroundStatus?> status() async => statusValue;
}
