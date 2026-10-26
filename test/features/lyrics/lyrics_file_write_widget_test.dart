import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    MemoryLyricsRepository lyrics,
    FakeTrackTagRepository tags,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await setUpTestDependencies(
      tracks: TestData.tracks,
      lyrics: lyrics,
      trackTags: tags,
    );
    tester.view.physicalSize = const Size(1170, 9000);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();
  }

  testWidgets('설정: 저장한 가사를 파일에 쓰기 → 곡 수 확인 → 결과 안내', (tester) async {
    final lyrics = MemoryLyricsRepository()
      ..saved[TestData.tracks[0].id] = '첫 곡 가사'
      ..saved[TestData.tracks[1].id] = '둘째 곡 가사';
    final tags = FakeTrackTagRepository(TagWriteResult.written);
    await pump(tester, lyrics, tags);

    await tester.tap(find.text('저장한 가사를 파일에 쓰기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('가사 2곡'), findsOneWidget);

    await tester.tap(find.text('쓰기'));
    await tester.pumpAndSettle();
    expect(find.text('가사 쓰기를 마쳤어요'), findsOneWidget);
    expect(find.text('2곡을 파일에 썼어요'), findsOneWidget);
    expect(tags.lyricsWritten.length, 2);
  });

  testWidgets('설정: 저장한 가사가 없으면 안내만 한다', (tester) async {
    await pump(tester, MemoryLyricsRepository(), FakeTrackTagRepository());
    await tester.tap(find.text('저장한 가사를 파일에 쓰기'));
    await tester.pumpAndSettle();
    expect(find.text('앱에 저장한 가사가 없어요'), findsOneWidget);
  });

  testWidgets('설정: 쓸 수 없는 환경이면 지원하지 않는다고 안내한다', (tester) async {
    final lyrics = MemoryLyricsRepository()
      ..saved[TestData.tracks[0].id] = '첫 곡 가사';
    await pump(tester, lyrics, FakeTrackTagRepository()); // 기본: unsupported
    await tester.tap(find.text('저장한 가사를 파일에 쓰기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('쓰기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('쓸 수 없어요'), findsOneWidget);
    expect(lyrics.saved.length, 1);
  });
}
