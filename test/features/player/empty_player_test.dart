import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/screens/player_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_data.dart';

void main() {
  testWidgets('대기열을 비우고 돌아오면 빈 플레이어는 닫힌다', (tester) async {
    await setUpTestDependencies(tracks: TestData.tracks);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MusicApp(initialLocation: Routes.home));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final vm = context.read<NowPlayingCubit>()
      ..playQueue(TestData.tracks, index: 0);
    context.push(Routes.player);
    await tester.pumpAndSettle();
    context.push(Routes.queue);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PlayerScreen), findsOneWidget);

    vm.clearQueue();
    await tester.pump(const Duration(seconds: 1));
    context.pop(); // 대기열 닫기
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PlayerScreen), findsNothing);
  });
}
