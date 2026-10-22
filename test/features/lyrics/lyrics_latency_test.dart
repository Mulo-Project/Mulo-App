import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/latency_calibration.dart';
import 'package:music_download_play_app/features/lyrics/presentation/bloc/lyrics_settings_cubit.dart';
import 'package:music_download_play_app/features/lyrics/presentation/screens/lyrics_latency_screen.dart';
import 'package:music_download_play_app/features/player/presentation/bloc/now_playing_cubit.dart';
import 'package:music_download_play_app/features/player/presentation/screens/player_screen.dart';

import '../../helpers/fakes.dart';

Track _t(String id) => Track(
  id: id,
  title: '첫 곡',
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, 1),
);

void main() {
  const calibration = LatencyCalibration();

  test('누른 시간이 가장 가까운 박자보다 늦으면 양수, 빠르면 음수', () {
    expect(calibration.offsetOf(3180), 180);
    expect(calibration.offsetOf(2950), -50);
    expect(calibration.offsetOf(2000), 0);
    expect(calibration.offsetOf(2500), 500);
  });

  test('추천 값은 처음 두 번을 버린 나머지의 중앙값이다', () {
    expect(LatencyCalibration.recommend([400, 300, 180, 200, 220]), 200);
    expect(LatencyCalibration.recommend([180, 200, 220, 240]), 230);
    expect(LatencyCalibration.recommend([]), isNull);
  });

  test('추천 값은 0 ~ 최대값 안으로 맞춘다', () {
    expect(LatencyCalibration.recommend([-90, -80, -70, -60, -50]), 0);
    expect(LatencyCalibration.recommend([900, 900, 800, 700, 900]), 500);
  });

  test('모자라게 눌렀으면 있는 것으로 계산한다', () {
    expect(LatencyCalibration.recommend([150]), 150);
  });

  testWidgets('보정 페이지: 버튼과 초기화로 값을 바꾸고 범위를 넘지 않는다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await setUpTestDependencies(tracks: [_t('t1')]);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PlayerScreen));
    final settings = ctx.read<LyricsSettingsCubit>();
    unawaited(showLyricsLatency(ctx));
    await tester.pumpAndSettle();

    expect(find.text('반응 시간 보정'), findsWidgets);
    expect(settings.state.latencyMs, 0);
    expect(find.text('0.00초'), findsOneWidget);

    await tester.tap(find.text('+0.01'));
    await tester.pumpAndSettle();
    expect(settings.state.latencyMs, 10);
    expect(find.text('0.01초'), findsOneWidget);

    await settings.setLatency(900);
    await tester.pumpAndSettle();
    expect(settings.state.latencyMs, 500);

    await tester.tap(find.text('기본값 0.20초로'));
    await tester.pumpAndSettle();
    expect(settings.state.latencyMs, 200);
    expect(find.text('0.20초'), findsOneWidget);
  });

  testWidgets('보정 페이지: 곡으로 확인은 지금 위치에서 보정만큼 앞당긴 위치를 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await setUpTestDependencies(tracks: [_t('t1')]);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.player));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(PlayerScreen));
    final player = ctx.read<NowPlayingCubit>()..playQueue([_t('t1')]);
    await tester.pumpAndSettle();
    unawaited(showLyricsLatency(ctx));
    await tester.pumpAndSettle();
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.text('+0.01'));
      await tester.pump();
    }
    expect(find.text('0.30초'), findsOneWidget);

    player.seekTo(const Duration(seconds: 5));
    await tester.pump();

    await tester.ensureVisible(find.text('찍어 보기'));
    await tester.tap(find.text('찍어 보기'));
    await tester.pumpAndSettle();
    expect(find.text('찍힌 위치 00:04.70'), findsOneWidget);
  });
}
