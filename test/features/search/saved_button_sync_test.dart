import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/app/app.dart';
import 'package:music_download_play_app/core/design/design.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/saved_video.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_stream.dart';
import 'package:music_download_play_app/features/search/domain/repositories/saved_video_repository.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/saved_videos_cubit.dart';

import '../../helpers/fakes.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('저장 목록에서 곡이 빠지면 상세 화면의 저장 버튼도 저장 안 됨으로 바뀐다', (tester) async {
    await setUpTestDependencies(
      engine: FakeDownloaderEngine(info: const VideoInfo(_a)),
      previewPlayer: FakePreviewPlayer(),
    );
    await sl<SavedVideoRepository>().save([
      SavedVideo(
        hit: _a,
        ready: true,
        sources: [VideoStream(url: 'https://example.com/a.m4a')],
      ),
    ]);
    await tester.pumpWidget(const MusicApp(initialLocation: '/search/saved'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Song A'));
    await settle(tester);
    final save = find.byKey(const ValueKey('detail-save'));
    expect(save, findsOneWidget);
    final before = tester.widget<PillButton>(save).label;

    // 다른 화면(저장한 음원)에서 삭제한 것과 같게 목록에서 뺀다.
    final cubit = tester.element(save).read<SavedVideosCubit>();
    await tester.runAsync(() => cubit.remove('a'));
    await settle(tester);

    expect(tester.widget<PillButton>(save).label, isNot(before));
  });
}
