import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/preview_page.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_quality.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_cubit.dart';

import '../../helpers/fakes.dart';

const _a = MediaHit(id: 'a', title: 'Song A', url: 'https://example.com/a');

/// 읽기부터 재생까지 네이티브가 하는 플레이어 (못 하는 경우는 [native]를 끈다).
class _NativePlayer extends FakePreviewPlayer {
  _NativePlayer({this.native = true});

  bool native;
  final pages = <PreviewPage>[];

  @override
  Future<bool> playPage(PreviewPage page) async {
    pages.add(page);
    if (native) playing = true;
    return native;
  }
}

PreviewCubit _cubit(FakeDownloaderEngine e, _NativePlayer p) => PreviewCubit(
  ResolveAudioStream(e),
  PlayPreview(p),
  RememberPreview(p),
  CurrentPreview(p),
  SeekPreview(p),
  PausePreview(p),
  ResumePreview(p),
  StopPreview(p),
  WatchPreviewCompleted(p),
  WatchPreviewProgress(p),
  WatchPreviewFailures(p),
  playPage: PlayPreviewPage(p),
);

void main() {
  group('미리 듣기: 읽기부터 재생까지 네이티브', () {
    test('네이티브가 시작하면 앱이 주소를 읽거나 재생을 부르지 않는다', () async {
      final player = _NativePlayer();
      final cubit = _cubit(FakeDownloaderEngine(), player);
      addTearDown(cubit.close);

      final failure = await cubit.toggle(_a);

      expect(failure, isNull);
      expect(cubit.state.status, PreviewStatus.playing);
      expect(player.pages.single.hit, _a);
      expect(player.played, isEmpty);
    });

    test('네이티브가 못 하면 예전 경로(엔진 라우팅)로 주소를 읽어 튼다', () async {
      final player = _NativePlayer(native: false);
      final cubit = _cubit(FakeDownloaderEngine(), player);
      addTearDown(cubit.close);

      final failure = await cubit.toggle(_a);

      expect(failure, isNull);
      expect(cubit.state.status, PreviewStatus.playing);
      expect(player.pages, hasLength(1));
      expect(player.played, ['https://stream.test/${_a.url}']);
    });

    test('화질을 정하지 않으면 기본 화질, 정하면 그 화질의 높이를 네이티브에 보낸다', () async {
      final player = _NativePlayer();
      final cubit = _cubit(FakeDownloaderEngine(), player);
      addTearDown(cubit.close);

      await cubit.toggle(_a);
      expect(player.pages.last.maxHeight, VideoQuality.standard.maxHeight);

      await cubit.toggle(_a, videoQuality: VideoQuality.high, forceStart: true);
      expect(player.pages.last.maxHeight, VideoQuality.high.maxHeight);
    });

    test('고른 오디오 언어를 네이티브에 그대로 보낸다', () async {
      final player = _NativePlayer();
      final cubit = _cubit(FakeDownloaderEngine(), player);
      addTearDown(cubit.close);

      await cubit.toggle(_a, audioLanguage: 'ko');

      expect(player.pages.single.audioLanguage, 'ko');
    });
  });
}
