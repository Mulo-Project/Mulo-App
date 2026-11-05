import 'package:flutter_test/flutter_test.dart';
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

  test('PreviewVideoCubit: 영상 주소를 읽어 알린다', () async {
    final cubit = PreviewVideoCubit(ResolveVideoStream(FakeDownloaderEngine()));
    await cubit.load('https://example.com/a');
    expect(cubit.state.url, 'https://video.test/https://example.com/a');
    await cubit.close();
  });
}
