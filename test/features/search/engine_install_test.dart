import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/engine/presentation/bloc/engine_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  test('EngineCubit: 확인하고 설치하면 설치됨으로 바뀐다', () async {
    final manager = FakeEngineManager();
    await setUpTestDependencies(engineManager: manager);
    final cubit = sl<EngineCubit>();
    await cubit.load();
    expect(cubit.state.status!.installed, isFalse);
    await cubit.install();
    expect(cubit.state.status!.installed, isTrue);
    expect(cubit.state.failed, isFalse);
  });

  test('EngineCubit: 설치에 실패하면 failed', () async {
    await setUpTestDependencies(
      engineManager: FakeEngineManager(failInstall: true),
    );
    final cubit = sl<EngineCubit>();
    await cubit.load();
    await cubit.install();
    expect(cubit.state.failed, isTrue);
    expect(cubit.state.status!.installed, isFalse);
  });

  testWidgets('설정: 엔진 줄에서 설치를 누르면 설치된 버전이 보인다', (tester) async {
    final manager = FakeEngineManager();
    await setUpTestDependencies(engineManager: manager);
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();

    expect(find.text('Download engine'), findsOneWidget);
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();
    expect(manager.installs, 1);
    expect(find.text('yt-dlp 2026.01.01'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('설정: 설치할 수 없는 기기(Android)에서는 엔진 줄이 없다', (tester) async {
    await setUpTestDependencies(
      engineManager: FakeEngineManager(supported: false),
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();
    expect(find.text('Download engine'), findsNothing);
  });

  testWidgets('설정: 로컬 엔진을 쓸 수 있으면 다운로드 모드가 로컬로 보인다', (tester) async {
    await setUpTestDependencies(
      engineManager: FakeEngineManager(installed: true),
    );
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();
    final pills = tester.widget<SegmentedPills<DownloadMode>>(
      find.byType(SegmentedPills<DownloadMode>),
    );
    expect(pills.selected, DownloadMode.local);
  });

  testWidgets('설정: 로컬 엔진이 없으면 서버 모드로 보인다', (tester) async {
    await setUpTestDependencies(engineManager: FakeEngineManager());
    await tester.pumpWidget(const MusicApp(initialLocation: Routes.settings));
    await tester.pumpAndSettle();
    final pills = tester.widget<SegmentedPills<DownloadMode>>(
      find.byType(SegmentedPills<DownloadMode>),
    );
    expect(pills.selected, DownloadMode.server);
  });
}
