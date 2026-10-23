import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/app/router.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/player/domain/entities/player_style.dart';
import 'package:music_download_play_app/features/player/presentation/widgets/player_common.dart';

import '../../helpers/fakes.dart';

Track _t(String id, String title) => Track(
  id: id,
  title: title,
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 9, int.parse(id.substring(1))),
);

void main() {
  for (final style in PlayerStyle.values) {
    for (final size in [const Size(1080, 2400), const Size(1080, 1920)]) {
      testWidgets('하단 조작부는 화면 높이의 3분의 1을 넘지 않는다: $style $size', (tester) async {
        await setUpTestDependencies(
          tracks: [_t('t1', '첫 곡'), _t('t2', '둘째 곡')],
          playerStyle: style,
        );
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.localesTestValue = const [Locale('ko')];
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await tester.pumpWidget(
          const MusicApp(initialLocation: Routes.library),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('첫 곡'));
        await tester.pumpAndSettle();
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .push(Routes.player);
        await tester.pumpAndSettle();
        final screen = tester.view.physicalSize.height / 3; // 화면 높이(논리)
        final r = tester.getRect(find.byType(PlayerControls));
        expect(r.height, lessThanOrEqualTo(screen / 3 + 0.5));
      });
    }
  }
}
