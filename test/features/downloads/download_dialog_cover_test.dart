import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';

import '../../helpers/fakes.dart';
import '../../helpers/open_download_dialog.dart';

const _url = 'https://i.test/a.jpg';

void main() {
  Future<MemoryDownloadQueue> open(
    WidgetTester tester, {
    List<DownloadItem> items = const [],
  }) async {
    final queue = MemoryDownloadQueue(items);
    await setUpTestDependencies(downloads: queue);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();
    return queue;
  }

  testWidgets('받기 팝업: 썸네일이 기본 커버로 넘어간다', (tester) async {
    final queue = await open(tester);
    await openDownloadDialog(tester, thumbnailUrl: _url);
    expect(find.text('커버'), findsOneWidget);
    // 기본 그대로면 "기본으로"는 보이지 않는다.
    expect(find.text('기본으로'), findsNothing);

    await tester.ensureVisible(find.text('받기').last);
    await tester.tap(find.text('받기').last);
    await tester.pumpAndSettle();

    expect(queue.requests.single.cover, const CoverArt.web(_url));
    expect(queue.requests.single.thumbnailUrl, _url);
  });

  testWidgets('받기 팝업: 이미지 페이지에서 이미지를 지우면 썸네일도 쓰지 않고 커버 없이 받는다', (tester) async {
    final queue = await open(tester);
    await openDownloadDialog(tester, thumbnailUrl: _url);
    await tester.tap(find.text('이미지 바꾸기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // 기본(썸네일) 그대로면 "기본 이미지로"는 없고 지우기(휴지통)만 있다.
    expect(find.text('기본 이미지로'), findsNothing);
    // 테스트에는 네트워크가 없어 이미지를 읽는 표시가 계속 돌므로 pumpAndSettle 대신 시간만 흘린다.
    await tester.tap(find.byKey(const ValueKey('cover-edit-remove')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('이미지 지우기').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('이미지 고르기'), findsOneWidget);

    await tester.ensureVisible(find.text('받기').last);
    await tester.tap(find.text('받기').last);
    await tester.pumpAndSettle();
    expect(queue.requests.single.cover, isNull);
    expect(queue.requests.single.thumbnailUrl, isNull);
  });

  testWidgets('받기 팝업: 썸네일이 없으면 커버 없이 받는다', (tester) async {
    final queue = await open(tester);
    await openDownloadDialog(tester);

    await tester.ensureVisible(find.text('받기').last);
    await tester.tap(find.text('받기').last);
    await tester.pumpAndSettle();

    expect(queue.requests.single.cover, isNull);
  });

  testWidgets('받기 팝업: 취소를 누르면 받지 않고 닫는다', (tester) async {
    final queue = await open(tester);
    await openDownloadDialog(tester, thumbnailUrl: _url);
    expect(find.text('받기 정보'), findsOneWidget);

    await tester.ensureVisible(find.text('취소'));
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('받기 정보'), findsNothing);
    expect(queue.requests, isEmpty);
  });

  testWidgets('받는 중인 곡을 취소하려면 한 번 더 확인한다', (tester) async {
    final queue = await open(
      tester,
      items: const [
        DownloadItem(
          id: 'a',
          title: 'Now Song',
          artist: 'Now Artist',
          status: DownloadStatus.downloading,
          progress: .5,
        ),
      ],
    );

    await tester.tap(find.byTooltip('취소').first);
    await tester.pumpAndSettle();
    expect(find.text('받기 취소'), findsOneWidget);
    expect(queue.controls, isEmpty);

    // 계속 받기: 그대로 둔다.
    await tester.tap(find.text('계속 받기'));
    await tester.pumpAndSettle();
    expect(queue.controls, isEmpty);

    await tester.tap(find.byTooltip('취소').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소하기'));
    await tester.pumpAndSettle();
    expect(queue.controls, ['cancel:a']);
  });
}
