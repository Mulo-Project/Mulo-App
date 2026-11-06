import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/entities/track_info.dart';
import 'package:music_download_play_app/features/playlists/domain/entities/playlist.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title, {String genre = '락'}) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  genre: genre,
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

final _dialogField = find.descendant(
  of: find.byType(AppDialog),
  matching: find.byType(EditableText),
);

void main() {
  Future<void> pumpLibrary(WidgetTester tester) async {
    await setUpTestDependencies(
      tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡'), _t('t3', '셋째 곡')],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
  }

  testWidgets('길게 누르면 선택 모드, 누르면 고르고 풀며 모두 풀면 끝난다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    // 팝업 메뉴가 아니라 선택 모드다.
    expect(find.text('상세 정보'), findsNothing);
    expect(find.text('1곡 선택'), findsOneWidget);
    expect(find.byTooltip('곡 메뉴'), findsNothing);

    await tester.tap(find.text('둘째 곡'));
    await tester.pumpAndSettle();
    expect(find.text('2곡 선택'), findsOneWidget);

    // 모두 선택은 "작업" 시트 안에 있다.
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsOneWidget);

    await tester.tap(find.byTooltip('선택 끝내기'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsNothing);
    expect(find.byTooltip('곡 메뉴'), findsWidgets);
  });

  testWidgets('고른 곡에 장르를 지정하면 확인창을 거쳐 그 곡들만 바뀐다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('둘째 곡'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    // 복수 작업 목록 바텀 시트.
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('장르 지정'));
    await tester.pumpAndSettle();
    await tester.enterText(_dialogField, '재즈');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    // 적용 전 확인창.
    expect(find.textContaining('고른 2곡의 장르를 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();

    // 선택 모드가 끝나고, 장르 탭에 재즈(2곡)와 락(1곡)이 나뉜다.
    expect(find.text('2곡 선택'), findsNothing);
    await tester.tap(find.text('장르'));
    await tester.pumpAndSettle();
    expect(find.text('재즈'), findsOneWidget);
    expect(find.text('2곡'), findsOneWidget);
    expect(find.text('락'), findsOneWidget);
  });

  testWidgets('확인창에서 취소하면 아무것도 바뀌지 않고 선택이 남는다', (tester) async {
    await pumpLibrary(tester);
    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('앨범 지정'));
    await tester.pumpAndSettle();
    await tester.enterText(_dialogField, '새 앨범');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('1곡 선택'), findsOneWidget);
    await tester.tap(find.byTooltip('선택 끝내기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('새 앨범'), findsNothing);
  });

  testWidgets('앨범 화면에서도 길게 눌러 고르고 장르를 한꺼번에 지정한다', (tester) async {
    await setUpTestDependencies(
      tracks: [
        _t('t1', '첫 곡'),
        _t('t2', '둘째 곡'),
        _t('t3', '셋째 곡', genre: '팝'),
      ],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(MusicApp(initialLocation: Routes.album('앨범')));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('첫 곡'));
    await tester.pumpAndSettle();
    expect(find.text('상세 정보'), findsNothing);
    expect(find.text('1곡 선택'), findsOneWidget);
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 선택'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsOneWidget);
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    // 고른 곡들의 값이 모두 같으면 입력창에 미리 채워진다 (앨범 · 아티스트는 같고 장르는 달라 빈 칸).
    await tester.tap(find.text('앨범 지정'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(_dialogField).controller.text, '앨범');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('아티스트 지정'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(_dialogField).controller.text, '가수');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    // 값이 곡마다 다른 종류(장르)는 비어 있다.
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('장르 지정'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(_dialogField).controller.text, '');
    await tester.enterText(_dialogField, '재즈');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.textContaining('고른 3곡의 장르를 바꿀까요?'), findsOneWidget);
    await tester.tap(find.text('바꾸기'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsNothing);
  });

  testWidgets('아티스트 탭에서 묶음을 길게 눌러 고르면 그 아티스트의 모든 곡이 고른 곡이 된다', (tester) async {
    await setUpTestDependencies(
      tracks: [
        _t('t1', '첫 곡'),
        _t('t2', '둘째 곡'),
        _t('t3', '셋째 곡').withInfo(
          const TrackInfo(title: '셋째 곡', artist: '다른 가수', album: '앨범'),
        ),
      ],
    );
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
    await tester.tap(find.text('아티스트'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('가수'));
    await tester.pumpAndSettle();
    expect(find.text('2곡 선택'), findsOneWidget);
    // 선택 모드에서는 묶음 줄을 눌러도 화면으로 가지 않고 푼다.
    await tester.tap(find.text('다른 가수'));
    await tester.pumpAndSettle();
    expect(find.text('3곡 선택'), findsOneWidget);
    await tester.tap(find.text('가수').first);
    await tester.pumpAndSettle();
    expect(find.text('1곡 선택'), findsOneWidget);
  });

  testWidgets('재생목록 상세에서도 곡을 골라 한꺼번에 빼거나 정보를 바꾼다', (tester) async {
    final tracks = [_t('t1', '첫 곡'), _t('t2', '둘째 곡'), _t('t3', '셋째 곡')];
    final playlists = MemoryPlaylistRepository(const [
      Playlist(id: 'pl1', name: '출근길'),
    ], tracks);
    await playlists.addTrack('t1', ['pl1']);
    await playlists.addTrack('t2', ['pl1']);
    await setUpTestDependencies(tracks: tracks, playlists: playlists);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MusicApp(initialLocation: Routes.playlistDetail('pl1')),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('첫 곡').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('둘째 곡').last);
    await tester.pumpAndSettle();
    expect(find.text('2곡 선택'), findsOneWidget);
    await tester.tap(find.text('작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('재생목록에서 빼기'));
    await tester.pumpAndSettle();
    expect(playlists.members['pl1'], isEmpty);
    expect(find.text('2곡 선택'), findsNothing);
  });
}
