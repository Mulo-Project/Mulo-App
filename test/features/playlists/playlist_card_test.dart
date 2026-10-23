import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_download_play_app/features/playlists/presentation/widgets/playlist_card.dart';

import '../../helpers/fakes.dart';

/// 1x1 PNG 파일 (꾸미기 화면이 실제로 읽을 수 있는 그림).
String _pngFile() {
  final dir = Directory.systemTemp.createTempSync('cover_test');
  addTearDown(() {
    // Windows는 이미지를 읽은 파일이 아직 열려 있으면 지우지 못하므로 못 지워도 테스트는 통과시킨다.
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // 임시 폴더라 남아도 괜찮다.
    }
  });
  return (File('${dir.path}/pick.png')..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
        ),
      ))
      .path;
}

/// 그림 파일은 실제 비동기로 읽으므로, 돌아가는 표시가 사라질 때까지 기다린다.
Future<void> _waitImage(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

/// 이미지 고르기 → 위치 맞추는 화면에서 이미지 불러오기 → 기기에서 → 적용.
Future<void> _pickFromDeviceAndApply(WidgetTester tester) async {
  await tester.tap(find.text('기기에서 고르기'));
  // 읽는 동안 돌아가는 표시가 있어 pumpAndSettle은 끝나지 않는다.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await _waitImage(tester);
  expect(find.text('적용'), findsOneWidget);
  await tester.tap(find.text('적용'));
  await tester.pumpAndSettle();
}

Track _t(String id, String title) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

void main() {
  late MemoryPlaylistRepository repo;
  late MemoryCoverRepository covers;
  late MemoryCoverColorRepository colors;

  setUp(() {
    final tracks = [_t('t1', '첫 곡'), _t('t2', '둘째 곡')];
    repo = MemoryPlaylistRepository(const [
      Playlist(
        id: 'pl1',
        name: '출근길',
        trackCount: 2,
        featured: PlaylistTrackPreview(id: 't1', title: '첫 곡', artist: '가수'),
      ),
      Playlist(id: 'pl2', name: '운동', trackCount: 5),
    ], tracks);
    repo.members['pl1'] = {'t1', 't2'};
    covers = MemoryCoverRepository();
    colors = MemoryCoverColorRepository();
  });

  Future<void> pumpPlaylists(
    WidgetTester tester, {
    FakeImageSource? image,
    MemoryDownloadQueue? downloads,
    List<Track>? tracks,
  }) async {
    await setUpTestDependencies(
      tracks: tracks ?? [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
      playlists: repo,
      covers: covers,
      coverColors: colors,
      imageSource: image,
      downloads: downloads,
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.playlists));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, {int card = 1}) async {
    await tester.tap(find.byTooltip('재생목록 메뉴').at(card));
    await tester.pumpAndSettle();
  }

  testWidgets('카드는 이름과 곡 수만 보이고(대표곡은 상세에서), 좋아요 목록이 맨 앞에 있다', (tester) async {
    await pumpPlaylists(tester);
    expect(find.text('출근길'), findsOneWidget);
    expect(find.text('첫 곡'), findsNothing);
    expect(find.textContaining('둘째 곡'), findsNothing);
    expect(find.text('좋아요'), findsOneWidget);
    // 좋아요가 첫 카드.
    expect(
      tester.getTopLeft(find.text('좋아요')).dx,
      lessThan(tester.getTopLeft(find.text('출근길')).dx),
    );
  });

  testWidgets('받는 중인 곡이 있으면 대표곡 자리에 그 곡과 진행 막대를 보인다', (tester) async {
    await pumpPlaylists(
      tester,
      downloads: MemoryDownloadQueue(const [
        DownloadItem(
          id: 'd1',
          title: '받는 곡',
          artist: '가수',
          status: DownloadStatus.downloading,
          progress: .4,
          playlistIds: {'pl1'},
        ),
      ]),
    );
    Finder inCard(Finder f) =>
        find.descendant(of: find.byType(PlaylistCard), matching: f);
    expect(inCard(find.text('받는 곡')), findsOneWidget);
    expect(inCard(find.textContaining('40%')), findsOneWidget);
    expect(inCard(find.byType(ProgressLine)), findsOneWidget);
    expect(find.text('첫 곡'), findsNothing);
  });

  testWidgets('⋮ 를 누르면 팝업 메뉴가 열린다 (바닥 시트 아님)', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    expect(find.byType(BottomSheet), findsNothing);
    for (final label in ['전체 재생', '꾸미기', '이름 바꾸기', '재생목록 삭제']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('길게 누르면 같은 메뉴가 열린다', (tester) async {
    await pumpPlaylists(tester);
    await tester.longPress(find.text('출근길'));
    await tester.pumpAndSettle();
    expect(find.text('꾸미기'), findsOneWidget);
    expect(find.text('재생목록 삭제'), findsOneWidget);
  });

  testWidgets('꾸미기 시트에서 색 견본으로 고르고 자동으로 되돌린다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('꾸미기'));
    await tester.pumpAndSettle();
    expect(find.text('색'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('색 7'));
    await tester.pumpAndSettle();
    expect(colors.saved['playlist:pl1'], ColorPicker.presets[6].toARGB32());

    await tester.tap(find.bySemanticsLabel('자동'));
    await tester.pumpAndSettle();
    expect(colors.saved.containsKey('playlist:pl1'), isFalse);
  });

  testWidgets('꾸미기 시트에서 이미지를 고르고 기본 이미지로 되돌린다', (tester) async {
    final path = _pngFile();
    await pumpPlaylists(tester, image: FakeImageSource(path));
    await openMenu(tester);
    await tester.tap(find.text('꾸미기'));
    await tester.pumpAndSettle();
    // 시트에는 이미지 줄 하나만 있고, 고르기 · 위치 · 되돌리기는 이미지 페이지 안에 있다.
    expect(find.text('이미지 고르기'), findsOneWidget);
    expect(find.text('기본 이미지로'), findsNothing);
    expect(find.text('위치 조정'), findsNothing);
    await tester.tap(find.text('이미지 고르기'));
    await tester.pumpAndSettle();
    await _pickFromDeviceAndApply(tester);
    expect(covers.saved['playlist:pl1'], CoverArt.file(path));
    expect(find.text('이미지 바꾸기'), findsOneWidget);
    expect(find.bySemanticsLabel('색 1'), findsOneWidget);

    // 줄을 다시 누르면 지금 이미지를 불러온 채 이미지 페이지가 열리고, 기본으로 되돌릴 때는 확인을 묻는다.
    await tester.tap(find.text('이미지 바꾸기'));
    await tester.pump();
    await _waitImage(tester);
    expect(find.text('기본 이미지로'), findsOneWidget);
    await tester.tap(find.text('기본 이미지로'));
    await tester.pumpAndSettle();
    expect(find.text('기본 이미지로 되돌릴까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(covers.saved, isNotEmpty);
    await tester.tap(find.text('기본 이미지로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 이미지로').last);
    await tester.pumpAndSettle();
    expect(covers.saved, isEmpty);
  });

  testWidgets('웹 이미지를 고르면 위치 맞추는 화면으로 간다 (읽지 못하면 적용할 수 없다)', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('꾸미기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이미지 고르기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('웹에서 가져오기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'https://x.test/a.jpg');
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 주소의 이미지 쓰기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('웹에서 가져오기'), findsOneWidget);
    // 테스트 환경은 네트워크가 없어 읽기에 실패하고, 그러면 저장되지 않는다.
    await _waitImage(tester);
    expect(find.text('이미지를 불러오지 못했어요'), findsOneWidget);
    expect(covers.saved, isEmpty);
  });

  testWidgets('대표곡은 상세 안에서 가수와 함께 보이고, 누르면 이 재생목록으로 재생한다', (tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.text('출근길'));
    await tester.pumpAndSettle();
    expect(find.text('대표곡'), findsOneWidget);
    // 대표곡 줄과 곡 목록에 모두 있다.
    expect(find.text('첫 곡'), findsNWidgets(2));
    expect(find.textContaining('가수 ·'), findsWidgets);
    expect(find.byTooltip('다음 곡'), findsNothing);

    await tester.tap(find.byTooltip('대표곡 미리 듣기'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('다음 곡'), findsOneWidget);
    // 재생 중이면 대표곡 줄의 버튼도 일시정지 아이콘으로 바뀐다 (미니 플레이어 것까지 둘).
    expect(find.byTooltip('대표곡 미리 듣기'), findsNothing);
    expect(find.byTooltip('일시정지'), findsNWidgets(2));
  });

  testWidgets('좋아요 목록 메뉴에는 이름 · 삭제가 없다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester, card: 0);
    expect(find.text('전체 재생'), findsOneWidget);
    expect(find.text('꾸미기'), findsOneWidget);
    expect(find.text('이름 바꾸기'), findsNothing);
    expect(find.text('재생목록 삭제'), findsNothing);
  });

  testWidgets('이름 바꾸기', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('이름 바꾸기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '퇴근길');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('퇴근길'), findsOneWidget);
    expect(find.text('출근길'), findsNothing);
  });

  testWidgets('삭제: 확인하면 재생목록이 사라진다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('재생목록 삭제'));
    await tester.pumpAndSettle();
    expect(find.textContaining('보관함에 그대로 남아요'), findsOneWidget);
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(find.text('출근길'), findsNothing);
    expect(find.text('재생목록을 지웠어요'), findsNothing); // 목록에서 사라지므로 안내는 없다
  });

  testWidgets('+ 버튼으로 이름 · 색을 골라 새 재생목록을 만든다', (tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.byTooltip('새 재생목록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '새 목록');
    await tester.tap(find.bySemanticsLabel('색 10'));
    await tester.pump();
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(find.text('새 목록'), findsOneWidget);
    expect(colors.saved['playlist:pl3'], ColorPicker.presets[9].toARGB32());
  });

  testWidgets('새 재생목록을 만들 때 이미지를 고르면 커버로 저장된다', (tester) async {
    final path = _pngFile();
    await pumpPlaylists(tester, image: FakeImageSource(path));
    await tester.tap(find.byTooltip('새 재생목록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '새 목록');
    await tester.tap(find.text('이미지 고르기'));
    await tester.pumpAndSettle();
    await _pickFromDeviceAndApply(tester);
    // 이미지를 골라도 색 고르기는 그대로 있다 (이미지를 지웠을 때 쓰인다).
    expect(find.text('이미지 바꾸기'), findsOneWidget);
    expect(find.bySemanticsLabel('색 1'), findsOneWidget);
    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    expect(covers.saved['playlist:pl3'], CoverArt.file(path));
    expect(colors.saved, isEmpty);
  });

  testWidgets('빈 재생목록 상세는 안내와 곡 추가 버튼이 있고, 보관함에서 곡을 골라 담는다', (tester) async {
    await pumpPlaylists(tester);
    await tester.tap(find.text('운동'));
    await tester.pumpAndSettle();
    // 큰 제목 한 줄 + 아래 작은 설명.
    expect(find.text('아직 담긴 곡이 없어요'), findsOneWidget);
    expect(find.textContaining('아래 ‘곡 추가’'), findsOneWidget);
    expect(find.byTooltip('곡 추가'), findsOneWidget); // 위 막대 버튼

    await tester.tap(find.widgetWithText(PillButton, '곡 추가'));
    await tester.pumpAndSettle();
    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('둘째 곡'), findsOneWidget);
    await tester.tap(find.text('첫 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1곡 추가'));
    await tester.pumpAndSettle();
    expect(repo.members['pl2'], {'t1'});
  });

  testWidgets('곡 추가 화면: 보관함과 같은 탭, 아티스트 줄을 누르면 그 곡이 모두 골라진다', (tester) async {
    Track by(String id, String title, String artist) => Track(
      id: id,
      title: title,
      artist: artist,
      album: '앨범',
      duration: const Duration(minutes: 3),
      uri: 'content://$id',
      addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
    );
    await pumpPlaylists(
      tester,
      tracks: [by('t1', '첫 곡', '가수A'), by('t2', '둘째 곡', '가수B')],
    );
    await tester.tap(find.text('운동'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PillButton, '곡 추가'));
    await tester.pumpAndSettle();
    // 곡 탭: 곡 줄이 보이고, 탭 넷이 있다.
    expect(find.text('첫 곡'), findsOneWidget);
    expect(find.text('아티스트'), findsOneWidget);
    expect(find.text('앨범'), findsOneWidget);
    expect(find.text('장르'), findsOneWidget);

    // 아티스트 탭: 묶음 줄을 누르면 그 아티스트의 곡이 모두 골라진다.
    await tester.tap(find.text('아티스트'));
    await tester.pumpAndSettle();
    expect(find.text('가수A'), findsOneWidget);
    expect(find.text('가수B'), findsOneWidget);
    expect(find.text('첫 곡'), findsNothing);
    // 줄을 누르면 그 아티스트의 곡이 펼쳐지고, 곡마다 골라 담을 수 있다.
    expect(find.text('둘째 곡'), findsNothing);
    await tester.tap(find.text('가수B'));
    await tester.pumpAndSettle();
    expect(find.text('둘째 곡'), findsOneWidget);
    await tester.tap(find.text('둘째 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1곡 추가'));
    await tester.pumpAndSettle();
    expect(repo.members['pl2'], {'t2'});
  });

  testWidgets('곡 추가 화면: 묶음 오른쪽 체크로 그 묶음의 곡을 한꺼번에 고른다', (tester) async {
    Track by(String id, String title, String artist) => Track(
      id: id,
      title: title,
      artist: artist,
      album: '앨범',
      duration: const Duration(minutes: 3),
      uri: 'content://$id',
      addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
    );
    await pumpPlaylists(
      tester,
      tracks: [
        by('t1', '첫 곡', '가수A'),
        by('t2', '둘째 곡', '가수B'),
        by('t3', '셋째 곡', '가수B'),
      ],
    );
    await tester.tap(find.text('운동'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PillButton, '곡 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('아티스트'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('모두 선택').last); // 가수B 묶음의 체크
    await tester.pumpAndSettle();
    expect(find.text('2곡 추가'), findsOneWidget);
    await tester.tap(find.text('2곡 추가'));
    await tester.pumpAndSettle();
    expect(repo.members['pl2'], {'t2', 't3'});
  });

  testWidgets('카드를 누르면 재생목록 상세로 가서 담긴 곡이 보이고, 곡 메뉴는 빼기 · 파일 삭제', (
    tester,
  ) async {
    await pumpPlaylists(tester);
    await tester.tap(find.text('출근길'));
    await tester.pumpAndSettle();
    // 상세: 탭 목록이 아니라 별도 페이지.
    expect(find.text('운동'), findsNothing);
    expect(find.text('첫 곡'), findsNWidgets(2)); // 대표곡 줄 + 곡 목록
    expect(find.text('둘째 곡'), findsOneWidget);
    expect(find.text('전체 재생'), findsOneWidget);

    await tester.tap(find.byTooltip('곡 메뉴').first);
    await tester.pumpAndSettle();
    expect(find.text('재생목록에서 빼기'), findsOneWidget);
    expect(find.text('파일 삭제'), findsOneWidget);
    await tester.tap(find.text('재생목록에서 빼기'));
    await tester.pumpAndSettle();
    expect(repo.members['pl1'], {'t2'});

    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('전체 재생: 담긴 곡으로 대기열이 채워져 미니 플레이어가 나온다', (tester) async {
    await pumpPlaylists(tester);
    await openMenu(tester);
    await tester.tap(find.text('전체 재생'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('다음 곡'), findsOneWidget);
  });
}
