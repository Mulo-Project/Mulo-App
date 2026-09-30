import 'dart:async';

import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/covers/di.dart';
import 'package:music_download_play_app/features/covers/domain/repositories/cover_repository.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_download_play_app/features/player/di.dart';
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
}

class FakeDeviceMusic implements DeviceMusicRepository {
  FakeDeviceMusic(this.result);

  ScanResult result;
  int calls = 0;

  @override
  Future<ScanResult> scan() async {
    calls++;
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

/// 앱 전체를 띄우는 테스트용 의존성 (DB · 파일 · 권한 없이).
/// 각 기능의 실제 등록을 쓰고 리포지토리만 가짜로 바꾼다.
Future<void> setUpTestDependencies({
  List<Track> tracks = const [],
  DeviceMusicRepository? device,
  CoverRepository? covers,
  CoverImageSource? imageSource,
  ThemeSettings theme = const ThemeSettings(),
}) async {
  await sl.reset();
  registerTheme(sl);
  registerLibrary(sl);
  registerCovers(sl);
  registerPlayer(sl);
  sl.allowReassignment = true;
  sl
    ..registerLazySingleton<ThemeSettingsRepository>(
      () => MemoryThemeSettingsRepository(theme),
    )
    ..registerLazySingleton<LibraryRepository>(
      () => FakeLibraryRepository(tracks),
    )
    ..registerLazySingleton<DeviceMusicRepository>(
      () => device ?? FakeDeviceMusic(const ScanFound([])),
    )
    ..registerLazySingleton<CoverRepository>(
      () => covers ?? MemoryCoverRepository(),
    )
    ..registerLazySingleton<CoverImageSource>(
      () => imageSource ?? FakeImageSource(),
    );
  sl.allowReassignment = false;
}
