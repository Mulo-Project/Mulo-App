import 'package:music_download_play_app/core/design/icons/app_icons.dart';

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/library/data/datasources/device_music_data_sources.dart';
import 'package:music_download_play_app/features/library/data/repositories/drift_library_repository.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';
import 'package:music_download_play_app/features/library/domain/entities/loaded_folder.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/usecases/library_usecases.dart';
import 'package:music_download_play_app/features/library/domain/usecases/loaded_folder_usecases.dart';
import 'package:music_download_play_app/features/library/presentation/bloc/loaded_folders_cubit.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String folder, {String? uri}) => Track(
  id: id,
  title: id,
  artist: '',
  album: '',
  duration: Duration.zero,
  uri: uri ?? '$folder/$id.mp3',
  folder: folder,
  addedAt: DateTime(2026, 10, 1),
);

LoadedFoldersCubit _cubit(
  MemoryLoadedFolders folders,
  FakeLibraryRepository library,
  FakeDeviceMusic device,
) => LoadedFoldersCubit(
  LoadLoadedFolders(folders, library),
  AddLoadedFolder(folders),
  RemoveLoadedFolder(folders, library),
  ImportDeviceMusic(device, library, folders),
);

void main() {
  test('폴더 경로: 구분자 맞추기와 하위 폴더 판정', () {
    expect(normalizeFolderPath(r'C:\Music\'), 'C:/Music');
    expect(isInsideFolder('/m/a/b', '/m/a'), isTrue);
    expect(isInsideFolder('/m/a', '/m/a/'), isTrue);
    expect(isInsideFolder('/m/ab', '/m/a'), isFalse);
    expect(isInsideFolder('', '/m/a'), isFalse);
  });

  test('목록: 기본 저장 위치가 맨 위, 폴더별 곡 수(하위 폴더 포함)', () async {
    final folders = MemoryLoadedFolders(extra: ['/music/extra']);
    final library = FakeLibraryRepository([
      _t('a', '/music/default'),
      _t('b', '/music/extra'),
      _t('c', '/music/extra/sub'),
    ]);
    final list = await LoadLoadedFolders(folders, library)(const NoParams());
    expect(list.map((f) => f.path), ['/music/default', '/music/extra']);
    expect(list.map((f) => f.trackCount), [1, 2]);
    expect(list.map((f) => f.isDefault), [true, false]);
  });

  test('추가: 취소 · 중복(기본 위치 포함)은 더하지 않는다', () async {
    final folders = MemoryLoadedFolders();
    final add = AddLoadedFolder(folders);
    expect(await add(const NoParams()), AddFolderResult.cancelled);
    folders.picked = '/music/default/';
    expect(await add(const NoParams()), AddFolderResult.duplicate);
    folders.picked = '/music/new/';
    expect(await add(const NoParams()), AddFolderResult.added);
    expect(await add(const NoParams()), AddFolderResult.duplicate);
    expect(folders.extra, ['/music/new']);
  });

  test('삭제: 기본 저장 위치는 지울 수 없다', () async {
    final folders = MemoryLoadedFolders(extra: ['/music/x']);
    final remove = RemoveLoadedFolder(folders, FakeLibraryRepository());
    expect(await remove('/music/default'), isNull);
    expect(await remove('/music/nope'), isNull);
    expect(await remove('/music/x'), isEmpty);
    expect(folders.extra, isEmpty);
  });

  test('삭제: 그 폴더에서 불러온 곡은 보관함에서 사라지고, 다른 폴더의 곡은 남는다', () async {
    final folders = MemoryLoadedFolders(extra: ['/music/x', '/music/x/deep']);
    final library = FakeLibraryRepository([
      _t('keep', '/music/default'),
      _t('x1', '/music/x'),
      _t('x2', '/music/x/sub'),
      _t('d1', '/music/x/deep'),
    ]);
    final remove = RemoveLoadedFolder(folders, library);
    expect(await remove('/music/x'), {'x1', 'x2'});
    final left = (await library.watchTracks().first).map((t) => t.id);
    // 남은 폴더(/music/x/deep) 안의 곡은 그대로 둔다.
    expect(left, unorderedEquals(['keep', 'd1']));
  });

  test('저장 위치: 불러오는 폴더를 더하면 따라 더해지고, 그 뒤로는 서로 따로 움직인다', () async {
    final folders = MemoryLoadedFolders()..picked = '/music/new';
    final library = FakeLibraryRepository([_t('n', '/music/new')]);
    await AddLoadedFolder(folders)(const NoParams());
    final load = LoadSaveLocations(folders);
    expect(await load(const NoParams()), ['/music/default', '/music/new']);

    // 저장 위치에서 빼도 불러오는 폴더와 곡은 그대로.
    await RemoveSaveLocation(folders)('/music/new');
    expect(await load(const NoParams()), ['/music/default']);
    expect(folders.extra, ['/music/new']);
    expect((await library.watchTracks().first).length, 1);

    // 불러오는 폴더를 빼도 저장 위치는 그대로.
    await AddSaveLocation(folders)('/music/other/');
    await RemoveLoadedFolder(folders, library)('/music/new');
    expect(await load(const NoParams()), ['/music/default', '/music/other']);
    // 기본 저장 위치는 뺄 수 없다.
    await RemoveSaveLocation(folders)('/music/default');
    expect((await load(const NoParams())).first, '/music/default');
  });

  test('저장 위치: 따로 저장한 적이 없으면 불러오는 폴더로 시작한다', () async {
    final folders = MemoryLoadedFolders(extra: ['/music/a']);
    expect(await LoadSaveLocations(folders)(const NoParams()), [
      '/music/default',
      '/music/a',
    ]);
  });

  test('목록이 바뀌면 보관함을 다시 스캔하고 곡 수를 새로 센다', () async {
    final folders = MemoryLoadedFolders()..picked = '/music/new';
    final library = FakeLibraryRepository();
    final device = FakeDeviceMusic(ScanFound([_t('n', '/music/new')]));
    final cubit = _cubit(folders, library, device);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.folders.length, 1);
    await cubit.add();
    expect(device.calls, 1);
    expect(device.lastFolders, ['/music/default', '/music/new']);
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.folders.last.trackCount, 1);

    await cubit.remove('/music/new');
    expect(device.calls, 2);
    expect(device.lastFolders, ['/music/default']);
    expect(cubit.state.folders.length, 1);

    // 기본 위치 삭제 · 취소는 스캔하지 않는다.
    await cubit.remove('/music/default');
    folders.picked = null;
    await cubit.add();
    expect(device.calls, 2);
  });

  test('데스크톱 스캔: 목록의 폴더만, 없는 폴더는 건너뛰고 중복 없음', () async {
    final dir = await Directory.systemTemp.createTemp('folders_scan');
    addTearDown(() => dir.delete(recursive: true));
    await Directory('${dir.path}/a/sub').create(recursive: true);
    await Directory('${dir.path}/b').create();
    await File('${dir.path}/a/one.mp3').create();
    await File('${dir.path}/a/sub/two.mp3').create();
    await File('${dir.path}/b/other.mp3').create();

    final result = await DirectoryMusicDataSource().scan([
      '${dir.path}/a',
      '${dir.path}/a/sub',
      '${dir.path}/missing',
    ]) as ScanFound;
    expect(result.tracks.map((t) => t.title), ['one', 'two']);
    expect(
      result.tracks.map((t) => t.folder),
      containsAll([
        normalizeFolderPath('${dir.path}/a'),
        normalizeFolderPath('${dir.path}/a/sub'),
      ]),
    );
  });

  test('DB: 폴더를 저장하고, 폴더 칸이 비어 있던 곡은 다시 찾을 때 채운다', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftLibraryRepository(db);
    await repo.addTracks([_t('a', '', uri: '/m/a.mp3')]);
    expect(await repo.addTracks([_t('a', '/m', uri: '/m/a.mp3')]), 0);
    expect((await repo.watchTracks().first).single.folder, '/m');
  });

  testWidgets('설정: 타일 부제에 폴더 수, 누르면 바텀 시트에 폴더와 곡 수', (tester) async {
    await setUpTestDependencies(
      tracks: [_t('a', '/music/default'), _t('b', '/music/extra')],
      folders: MemoryLoadedFolders(extra: ['/music/extra']),
    );
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();

    expect(find.text('불러오는 폴더'), findsOneWidget);
    expect(find.text('2개 폴더'), findsOneWidget);

    await tester.tap(find.text('불러오는 폴더'));
    await tester.pumpAndSettle();
    expect(find.text('/music/default'), findsOneWidget);
    expect(find.text('기본 저장 위치 · 1곡'), findsOneWidget);
    expect(find.text('/music/extra'), findsOneWidget);
    expect(find.text('1곡'), findsOneWidget);
    expect(find.text('폴더 추가'), findsOneWidget);
    // 기본 저장 위치에는 삭제 버튼이 없다.
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });
}
