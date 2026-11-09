import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_cubit.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';
import 'package:music_download_play_app/features/search/presentation/bloc/preview_video_cubit.dart';

import '../../helpers/fakes.dart';

Track _track(String id, {String uri = 'content://1'}) => Track(
  id: id,
  title: 't',
  artist: '',
  album: '',
  duration: Duration.zero,
  uri: uri,
  addedAt: DateTime(2026, 11, 5),
);

void main() {
  group('Track.isVideo', () {
    test('기기에서 불러온 영상 곡 id는 영상이다', () {
      expect(_track('${Track.videoIdPrefix}7').isVideo, isTrue);
    });

    test('음악 곡은 영상이 아니다', () {
      expect(_track('device:7').isVideo, isFalse);
    });

    test('파일 경로로 불러온 곡은 확장자로 가른다', () {
      expect(_track('file:/a/b.mp4', uri: '/a/b.MP4').isVideo, isTrue);
      expect(_track('file:/a/b.mp3', uri: '/a/b.mp3').isVideo, isFalse);
    });
  });

  test('PreviewVideoCubit: 영상 주소를 읽어 네이티브에 틀라고 한다', () async {
    final player = FakePreviewPlayer();
    final cubit = PreviewVideoCubit(
      ResolveVideoStream(FakeDownloaderEngine()),
      PlayPreviewVideo(player),
    );
    expect(cubit.state.started, isFalse);
    await cubit.load('https://example.com/a');
    expect(cubit.state.started, isTrue);
    expect(player.playedVideos, ['https://video.test/https://example.com/a']);
    await cubit.close();
  });

  test('PreviewCubit: 유튜브는 소리가 섞인 영상 주소 하나로 소리와 영상을 튼다', () async {
    const hit = MediaHit(
      id: 'y',
      title: 'Y',
      url: 'https://www.youtube.com/watch?v=abc',
    );
    for (final muxed in [true, false]) {
      final engine = FakeDownloaderEngine(muxedVideo: muxed);
      final p = FakePreviewPlayer();
      final cubit = PreviewCubit(
        ResolveAudioStream(engine),
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
        resolveVideo: ResolveVideoStream(engine),
      );
      await cubit.toggle(hit);
      // 소리가 섞인 형식이면 그 주소로, 아니면 소리 주소를 따로 읽어서 튼다.
      expect(
        p.played.single.startsWith('https://video.test/'),
        muxed,
      );
      await cubit.close();
    }
  });
}
