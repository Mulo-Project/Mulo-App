import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_item.dart';
import 'package:music_download_play_app/features/notifications/domain/repositories/download_notifier.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_cubit.dart';

import '../../helpers/fakes.dart';

/// 받기 알림의 "취소" · "미리 듣기" 버튼이 앱까지 이어지는지 (알림 → 앱의 받기 대기열 · 미리 듣기).
void main() {
  Future<(MemoryDownloadQueue, FakeDownloadNotifier)> boot(
    WidgetTester tester,
  ) async {
    final queue = MemoryDownloadQueue([
      const DownloadItem(
        id: 'd1',
        title: '받는 곡',
        artist: '가수',
        url: 'https://youtu.be/abc',
        status: DownloadStatus.downloading,
        progress: .3,
      ),
    ]);
    await setUpTestDependencies(downloads: queue);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.library));
    await tester.pumpAndSettle();
    return (queue, sl<DownloadNotifier>() as FakeDownloadNotifier);
  }

  testWidgets('알림의 취소 버튼은 지금 받는 곡을 취소한다', (tester) async {
    final (queue, notifier) = await boot(tester);
    notifier.press(DownloadNotificationAction.cancel);
    await tester.pumpAndSettle();
    expect(queue.controls, contains('cancel:d1'));
  });

  testWidgets('알림의 미리 듣기 버튼은 지금 받는 곡을 받지 않고 바로 듣는다', (tester) async {
    final (_, notifier) = await boot(tester);
    // 앱이 쓰는 미리 듣기 (sl에서 새로 만든 것이 아니라 화면 트리의 것).
    final preview = BlocProvider.of<PreviewCubit>(
      tester.element(find.byType(Scaffold).first),
    );
    notifier.press(DownloadNotificationAction.preview);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(preview.state.isActive('d1'), isTrue);

    // 같은 곡이 이미 들리는 중이면 다시 눌러도 그대로이고, 멈춤 버튼은 멈춘다.
    notifier.press(DownloadNotificationAction.preview);
    await tester.pump(const Duration(milliseconds: 100));
    expect(preview.state.isActive('d1'), isTrue);
    notifier.press(DownloadNotificationAction.stopPreview);
    await tester.pump(const Duration(milliseconds: 100));
    expect(preview.state.isActive('d1'), isFalse);
  });
}
