import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/saved_video.dart';
import 'package:music_download_play_app/features/search/domain/repositories/saved_video_repository.dart';

import '../../helpers/fakes.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');
const _b = MediaHit(id: 'b', title: 'Song B', url: 'https://example.com/b');

/// 끝나지 않는 움직임(재생 표시 등)이 있어 pumpAndSettle 대신 몇 프레임만 돌린다.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('저장한 음원: 전체 재생을 누르면 상세 + 재생 조작이 열리고 다음 곡으로 넘어간다', (tester) async {
    final player = FakePreviewPlayer();
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(),
      previewPlayer: player,
    );
    await sl<SavedVideoRepository>().save(const [
      SavedVideo(hit: _a),
      SavedVideo(hit: _b),
    ]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('saved-play-all')));
    await settle(tester);
    expect(player.playing, isTrue);
    expect(find.byKey(const ValueKey('queue-bar-play')), findsOneWidget);
    expect(find.byKey(const ValueKey('queue-bar-seek')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('queue-bar-next')));
    await settle(tester);
    expect(player.played.length, 2);

    await tester.tap(find.byKey(const ValueKey('queue-bar-queue')));
    await settle(tester);
    expect(find.text('Song A'), findsWidgets);
    expect(find.text('Song B'), findsWidgets);
  });
}
