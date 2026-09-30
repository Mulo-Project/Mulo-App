import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/core/sample/sample_data.dart';
import 'package:music_download_play_app/features/library/domain/entities/import_result.dart';

import 'helpers/fakes.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  String at = Routes.library,
  double height = 2532,
  Future<void> Function()? setUp,
}) async {
  await (setUp ?? () => setUpTestDependencies(tracks: SampleData.tracks))();
  tester.view.physicalSize = Size(1170, height);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.localesTestValue = const [Locale('ko')];
  // 앱은 기기 밝기를 따르지 않는다 (기본 다크). 기기를 라이트로 둬도 다크여야 한다.
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(MusicApp(initialLocation: at));
  await tester.pumpAndSettle();
}

AppPalette _palette(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(AppBottomNav)))
        .extension<AppThemeTokens>()!
        .palette;

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(AppBottomNav))).brightness;

void main() {
  testWidgets('보관함에서 시작하고 하단 탭으로 이동한다', (tester) async {
    await _pumpApp(tester);
    expect(find.text('보관함'), findsWidgets);
    // 처음에는 재생 중인 곡이 없어 미니 플레이어가 없다.
    expect(find.byType(MiniPlayerBar), findsNothing);

    // 다운로드는 탭이 아니라 검색 탭에 합쳐졌다 (검색창 아래 카드).
    expect(find.text('다운로드'), findsNothing);
    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();
    expect(find.text('유튜브'), findsOneWidget);
  });

  testWidgets('설정에서 테마 프리셋을 고르면 팔레트가 바뀐다', (tester) async {
    await _pumpApp(tester, at: Routes.settings, height: 7000);
    expect(_palette(tester).accent, AppPalette.lime);

    await tester.tap(find.text('코랄'));
    await tester.pumpAndSettle();
    expect(_palette(tester).accent, isNot(AppPalette.lime));
    expect(_palette(tester).background, AppPalette.black);

    await tester.tap(find.text('바이올렛'));
    await tester.pumpAndSettle();
    expect(_palette(tester).accent, AppPalette.lime);
  });

  testWidgets('화면 모드: 라이트를 고르면 밝은 배경, 다크로 돌아온다', (tester) async {
    await _pumpApp(tester, at: Routes.settings, height: 7000);
    await tester.tap(find.text('라이트'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
    expect(_palette(tester).background.computeLuminance(), greaterThan(.8));

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(_palette(tester).background, AppPalette.black);
  });

  testWidgets('곡을 누르면 미니 플레이어가 뜨고, 누르면 전체 화면 플레이어', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text(SampleData.tracks.first.title).first);
    await tester.pumpAndSettle();
    expect(find.byType(MiniPlayerBar), findsOneWidget);
    await tester.tap(find.byType(MiniPlayerBar));
    await tester.pumpAndSettle();
    expect(find.text('지금 재생 중'), findsOneWidget);
  });

  testWidgets('보관함: 정렬 드롭다운으로 기준을 바꾸고, 장르 탭에서 장르별로 본다', (tester) async {
    await _pumpApp(tester);
    expect(find.text('추가일순'), findsOneWidget);
    await tester.tap(find.text('추가일순'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이름순'));
    await tester.pumpAndSettle();
    expect(find.text('이름순'), findsOneWidget);

    await tester.tap(find.text('장르'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackTile), findsWidgets);
    await tester.tap(find.byType(TrackTile).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('장르 목록으로'), findsOneWidget);
    await tester.tap(find.byTooltip('장르 목록으로'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('장르 목록으로'), findsNothing);
  });

  testWidgets('빈 보관함: 불러오기 버튼으로 기기 음악을 추가한다', (tester) async {
    final device = FakeDeviceMusic(
      ScanFound(SampleData.tracks.take(3).toList()),
    );
    await _pumpApp(tester, setUp: () => setUpTestDependencies(device: device));
    expect(find.text('아직 음악이 없어요'), findsOneWidget);

    await tester.tap(find.text('기기 음악 불러오기').last);
    await tester.pumpAndSettle();
    expect(device.calls, 1);
    expect(find.text('3곡을 불러왔어요'), findsOneWidget);
    expect(find.text(SampleData.tracks.first.title), findsWidgets);
  });

  testWidgets('곡을 재생하면 홈의 최근 재생 · 많이 들은 곡에 나온다', (tester) async {
    final history = MemoryPlayHistory();
    await _pumpApp(
      tester,
      setUp: () =>
          setUpTestDependencies(tracks: SampleData.tracks, history: history),
    );
    final first = SampleData.tracks.reduce(
      (a, b) => a.addedAt.isAfter(b.addedAt) ? a : b,
    );
    await tester.tap(find.text(first.title).first);
    await tester.pumpAndSettle();
    expect(history.plays.map((p) => p.trackId), [first.id]);

    await tester.tap(find.text('홈').last);
    await tester.pumpAndSettle();
    expect(find.text('많이 들은 곡'), findsOneWidget);
    expect(find.text(first.title), findsWidgets);
    expect(find.text('1회'), findsOneWidget);
  });

  testWidgets('홈: 보관함이 비었으면 보관함으로 안내', (tester) async {
    await _pumpApp(
      tester,
      at: Routes.home,
      setUp: () => setUpTestDependencies(),
    );
    expect(find.text('보관함이 비었어요'), findsOneWidget);
    await tester.tap(find.text('보관함으로'));
    await tester.pumpAndSettle();
    expect(find.text('아직 음악이 없어요'), findsOneWidget);
  });

  test('derive는 강조 색 대비를 보정한다', () {
    final p = AppPalette.derive(
      primary: const Color(0xFF220044),
      accent: const Color(0xFF111133),
    );
    expect(contrastRatio(p.accent, p.background), greaterThanOrEqualTo(7));
    expect(p.background, AppPalette.black);
  });
}
