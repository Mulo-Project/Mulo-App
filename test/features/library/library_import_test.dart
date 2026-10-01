import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/library/data/datasources/device_music_data_sources.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/usecases/library_usecases.dart';
import 'package:music_download_play_app/features/library/presentation/bloc/library_import_cubit.dart';

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

void main() {
  test('ImportDeviceMusic: 찾은 곡을 추가하고 새 곡 수를 알려 준다', () async {
    final useCase = ImportDeviceMusic(
      FakeDeviceMusic(ScanFound([_song])),
      FakeLibraryRepository(),
      MemoryLoadedFolders(),
    );
    expect((await useCase(const NoParams()) as ImportAdded).count, 1);
    expect((await useCase(const NoParams()) as ImportAdded).count, 0);
  });

  test('ImportDeviceMusic: 권한 거절 · 취소', () async {
    final device = FakeDeviceMusic(const ScanPermissionDenied());
    final useCase = ImportDeviceMusic(
      device,
      FakeLibraryRepository(),
      MemoryLoadedFolders(),
    );
    expect(await useCase(const NoParams()), isA<ImportDenied>());
    device.result = const ScanCancelled();
    expect(await useCase(const NoParams()), isA<ImportCancelled>());
  });

  test('LibraryImportCubit: 실행 중 표시 후 결과와 seq를 올린다', () async {
    final cubit = LibraryImportCubit(
      ImportDeviceMusic(
        FakeDeviceMusic(ScanFound([_song])),
        FakeLibraryRepository(),
        MemoryLoadedFolders(),
      ),
    );
    addTearDown(cubit.close);
    final states = <LibraryImportState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.importDeviceMusic();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states.first.running, isTrue);
    expect(states.last.running, isFalse);
    expect(states.last.seq, 1);
    expect((states.last.outcome! as ImportAdded).count, 1);
  });

  test('폴더 스캔: 음악 확장자만, 하위 폴더 포함, 파일 이름이 제목', () async {
    final dir = await Directory.systemTemp.createTemp('music_scan');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/b song.mp3').create();
    await Directory('${dir.path}/sub').create();
    await File('${dir.path}/sub/a.FLAC').create();
    await File('${dir.path}/cover.jpg').create();

    final tracks = await DirectoryMusicDataSource().scanDirectory(dir);
    expect(tracks.map((t) => t.title), ['a', 'b song']);
    expect(tracks.every((t) => File(t.uri).existsSync()), isTrue);
  });
}
