import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/downloads/domain/usecases/download_usecases.dart';
import 'package:music_download_play_app/features/downloads/presentation/bloc/download_queue_cubit.dart';

import '../../helpers/fakes.dart';

const _now = DownloadItem(
  id: 'a',
  title: 'Now Song',
  artist: 'Now Artist',
  status: DownloadStatus.downloading,
  progress: .5,
);
const _next = DownloadItem(
  id: 'b',
  title: 'Next Song',
  artist: 'Next Artist',
  status: DownloadStatus.queued,
);
const _done = DownloadItem(
  id: 'c',
  title: 'Done Song',
  artist: 'Done Artist',
  status: DownloadStatus.done,
  progress: 1,
);

void main() {
  test('cubit: 받는 곡과 대기 곡을 나눈다 (완료는 제외)', () async {
    final repo = MemoryDownloadQueue([_next, _now, _done]);
    final cubit = DownloadQueueCubit(WatchDownloadQueue(repo))..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, _now);
    expect(cubit.state.waiting, [_next]);

    repo.set([_done]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.current, isNull);
    expect(cubit.state.waiting, isEmpty);
    await cubit.close();
  });

  Future<void> open(WidgetTester tester, List<DownloadItem> queue) async {
    await setUpTestDependencies(downloads: MemoryDownloadQueue(queue));
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(sl.reset);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.search));
    await tester.pumpAndSettle();
  }

  testWidgets('검색 탭: 받는 카드 → 화살표로 대기 목록 펼침', (tester) async {
    await open(tester, [_now, _next]);
    expect(find.text('Now Song'), findsOneWidget);
    expect(find.text('Next Song · Next Artist'), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Next Song · Next Artist'), findsOneWidget);
  });

  testWidgets('검색 탭: 받는 곡이 없으면 카드가 없다', (tester) async {
    await open(tester, [_done]);
    expect(find.text('Done Song'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
  });

  testWidgets('검색 대상 메뉴: 유튜브 → 웹', (tester) async {
    await open(tester, const []);
    expect(find.text('유튜브'), findsOneWidget);
    await tester.tap(find.text('유튜브'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('웹').last);
    await tester.pumpAndSettle();
    expect(find.text('웹'), findsOneWidget);
    expect(find.text('웹 음원 검색어나 URL'), findsOneWidget);
  });
}
