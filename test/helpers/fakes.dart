import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/covers/presentation/cover_controller.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/library_repository.dart';
import 'package:music_download_play_app/features/library/domain/track.dart';

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

class FakeScanner implements DeviceMusicScanner {
  FakeScanner(this.result);

  ScanResult result;
  int calls = 0;

  @override
  Future<ScanResult> scan() async {
    calls++;
    return result;
  }
}

/// 파일 복사 없이 경로만 기억하는 커버 저장소.
class MemoryCoverStore implements CoverStore {
  final saved = <String, String>{};

  @override
  Future<Map<String, String>> loadAll() async => {...saved};

  @override
  Future<String> save(String key, String sourcePath) async =>
      saved[key] = sourcePath;

  @override
  Future<void> remove(String key) async => saved.remove(key);
}

class MemoryThemeStore implements ThemePreferenceStore {
  String? preset;
  String? mode;

  @override
  Future<String?> loadPresetId() async => preset;

  @override
  Future<void> savePresetId(String id) async => preset = id;

  @override
  Future<String?> loadMode() async => mode;

  @override
  Future<void> saveMode(String m) async => mode = m;
}

/// 앱 전체를 띄우는 테스트용 기본 교체 (DB · 파일 · 권한 없이).
List<Override> appTestOverrides({
  List<Track> tracks = const [],
  DeviceMusicScanner? scanner,
  CoverStore? covers,
  String? themeMode,
}) => [
  libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository(tracks)),
  deviceMusicScannerProvider.overrideWithValue(
    scanner ?? FakeScanner(const ScanFound([])),
  ),
  coverStoreProvider.overrideWithValue(covers ?? MemoryCoverStore()),
  themePreferenceStoreProvider.overrideWithValue(
    MemoryThemeStore()..mode = themeMode,
  ),
];
