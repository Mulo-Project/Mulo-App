import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/data/device_music_scanners.dart';
import 'package:music_download_play_app/features/library/di.dart';
import 'package:music_download_play_app/features/library/domain/library_repository.dart';
import 'package:music_download_play_app/features/library/domain/track.dart';
import 'package:music_download_play_app/features/library/presentation/library_import_view_model.dart';

import '../../helpers/fakes.dart';

final _song = Track(
  id: 'device:1',
  title: 'Song',
  artist: '',
  album: '',
  duration: Duration.zero,
  uri: 'content://1',
  addedAt: DateTime(2026, 9, 30),
);

ProviderContainer _container(FakeScanner scanner, FakeLibraryRepository repo) =>
    ProviderContainer(
      overrides: [
        deviceMusicScannerProvider.overrideWithValue(scanner),
        libraryRepositoryProvider.overrideWithValue(repo),
      ],
    );

void main() {
  test('찾은 곡을 추가하고 새 곡 수를 알려 준다', () async {
    final c = _container(
      FakeScanner(ScanFound([_song])),
      FakeLibraryRepository(),
    );
    addTearDown(c.dispose);
    final vm = c.read(libraryImportProvider.notifier);
    final first = await vm.importDeviceMusic();
    expect((first! as ImportAdded).count, 1);
    final again = await vm.importDeviceMusic();
    expect((again! as ImportAdded).count, 0);
    expect(c.read(libraryImportProvider).running, isFalse);
  });

  test('권한 거절 · 취소', () async {
    final scanner = FakeScanner(const ScanPermissionDenied());
    final c = _container(scanner, FakeLibraryRepository());
    addTearDown(c.dispose);
    final vm = c.read(libraryImportProvider.notifier);
    expect(await vm.importDeviceMusic(), isA<ImportDenied>());
    scanner.result = const ScanCancelled();
    expect(await vm.importDeviceMusic(), isNull);
  });

  test('폴더 스캔: 음악 확장자만, 하위 폴더 포함, 파일 이름이 제목', () async {
    final dir = await Directory.systemTemp.createTemp('music_scan');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/b song.mp3').create();
    await Directory('${dir.path}/sub').create();
    await File('${dir.path}/sub/a.FLAC').create();
    await File('${dir.path}/cover.jpg').create();

    final tracks = await DirectoryMusicScanner().scanDirectory(dir);
    expect(tracks.map((t) => t.title), ['a', 'b song']);
    expect(tracks.every((t) => File(t.uri).existsSync()), isTrue);
  });
}
