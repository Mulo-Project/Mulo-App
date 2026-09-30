// 화면 스크린샷 (기본은 건너뜀).
// 실행: flutter test --run-skipped -t screenshot test/screenshots
// 결과: build/screenshots/<locale>-<화면>.png
@Tags(['screenshot'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/core/sample/sample_data.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/theme/domain/entities/theme_settings.dart';

import '../helpers/fakes.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      final bytes = File(p).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Pretendard', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/pretendard/Pretendard-$w.otf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  const screens = {
    'home': Routes.home,
    'home-light': Routes.home,
    'library': Routes.library,
    'playlists': Routes.playlists,
    'search': Routes.search,
    'search-url': '${Routes.search}?q=https://youtu.be/example',
    'search-playlist':
        '${Routes.search}?q=https://youtube.com/playlist?list=example',
    'search-keyword': '${Routes.search}?q=night',
    'downloads': Routes.downloads,
    'settings': Routes.settings,
    'settings-full': Routes.settings,
    'library-light': Routes.library,
    'playlists-light': Routes.playlists,
    'settings-full-light': Routes.settings,
    'player-light': Routes.player,
    'player': Routes.player,
  };

  for (final locale in ['ko', 'en']) {
    for (final e in screens.entries) {
      testWidgets('screenshot $locale-${e.key}', (tester) async {
        await tester.runAsync(_loadFonts);
        tester.view.physicalSize = Size(
          1080,
          e.key.contains('-full') ? 6400 : 2424,
        );
        tester.view.devicePixelRatio = 2.75;
        tester.platformDispatcher.localesTestValue = [Locale(locale)];
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        // 홈 스크린샷용 가짜 재생 기록 (최근 며칠).
        final now = DateTime.now();
        final plays = [
          for (var i = 0; i < 14; i++)
            PlayRecord(
              trackId: SampleData.tracks[(i * 5) % 7].id,
              playedAt: now.subtract(Duration(hours: i * 7)),
            ),
        ];
        await setUpTestDependencies(
          history: MemoryPlayHistory(plays),
          tracks: SampleData.tracks,
          // 라이트 스크린샷은 저장된 화면 모드를 라이트로 둔다.
          theme: ThemeSettings(
            mode: e.key.endsWith('-light')
                ? AppThemeMode.light
                : AppThemeMode.dark,
          ),
        );
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MusicApp(initialLocation: e.value),
          ),
        );
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('build/screenshots/$locale-${e.key}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      }, skip: true);
    }
  }
}
