import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/search/domain/entities/engine_exception.dart';
import 'package:music_download_play_app/features/search/domain/entities/media_info.dart';
import 'package:music_download_play_app/features/search/domain/entities/saved_video.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_quality.dart';
import 'package:music_download_play_app/features/search/domain/entities/video_stream.dart';
import 'package:music_download_play_app/features/search/domain/repositories/saved_video_repository.dart';
import 'package:music_download_play_app/features/search/domain/usecases/search_usecases.dart';

import '../../helpers/fakes.dart';

class _Repo implements SavedVideoRepository {
  _Repo(this.list);

  List<SavedVideo> list;

  @override
  Future<List<SavedVideo>> load() async => list;

  @override
  Future<void> save(List<SavedVideo> videos) async => list = videos;
}

const _hit = MediaHit(id: 'v', title: 'Song', url: 'https://yt/v');

void main() {
  group('저장한 곡은 링크를 풀지 않고 저장한 주소를 쓴다', () {
    test('받기가 끝난 곡: 소리 · 영상 모두 엔진을 부르지 않는다', () async {
      final engine = FakeDownloaderEngine();
      final repo = _Repo([
        const SavedVideo(
          hit: _hit,
          ready: true,
          quality: VideoQuality.standard,
          sources: [VideoStream(url: 'saved://mux', muxed: true)],
        ),
      ]);
      final audio = await ResolveAudioStream(engine, repo)(_hit.url);
      final video = await ResolveVideoStream(engine, null, repo)(
        _hit.url,
        quality: VideoQuality.standard,
      );
      expect(audio.url, 'saved://mux');
      expect(video.url, 'saved://mux');
      expect(engine.videoHeights, isEmpty);
    });

    test('아직 받는 중이면 링크를 푼다', () async {
      final engine = FakeDownloaderEngine();
      final repo = _Repo([
        const SavedVideo(
          hit: _hit,
          quality: VideoQuality.standard,
          sources: [VideoStream(url: 'saved://mux', muxed: true)],
        ),
      ]);
      await ResolveVideoStream(engine, null, repo)(
        _hit.url,
        quality: VideoQuality.standard,
      );
      expect(engine.videoHeights, isNotEmpty);
    });

    test('소리만 저장한 곡은 영상 주소를 읽지 않는다', () async {
      final engine = FakeDownloaderEngine();
      final repo = _Repo([
        const SavedVideo(
          hit: _hit,
          ready: true,
          sources: [VideoStream(url: 'saved://audio')],
        ),
      ]);
      await expectLater(
        ResolveVideoStream(engine, null, repo)(_hit.url),
        throwsA(isA<EngineException>()),
      );
      final audio = await ResolveAudioStream(engine, repo)(_hit.url);
      expect(audio.url, 'saved://audio');
    });

    test('영상 전용 + 소리 전용: 영상은 앞, 소리는 뒤 주소', () async {
      final engine = FakeDownloaderEngine();
      final repo = _Repo([
        const SavedVideo(
          hit: _hit,
          ready: true,
          quality: VideoQuality.high,
          sources: [
            VideoStream(url: 'saved://video'),
            VideoStream(url: 'saved://audio'),
          ],
        ),
      ]);
      final video = await ResolveVideoStream(engine, null, repo)(
        _hit.url,
        quality: VideoQuality.high,
      );
      final audio = await ResolveAudioStream(engine, repo)(_hit.url);
      expect(video.url, 'saved://video');
      expect(audio.url, 'saved://audio');
    });

    test('링크를 못 풀면(오프라인) 받다 만 곡도 받은 데이터만큼 튼다', () async {
      final engine = FakeDownloaderEngine(
        error: const EngineException(EngineFailure.network),
      );
      final repo = _Repo([
        const SavedVideo(
          hit: _hit,
          sources: [VideoStream(url: 'saved://part', muxed: true)],
        ),
      ]);
      final audio = await ResolveAudioStream(engine, repo)(_hit.url);
      expect(audio.url, 'saved://part');
      // 저장하지 않은 곡은 그대로 실패한다.
      await expectLater(
        ResolveAudioStream(engine, _Repo([]))(_hit.url),
        throwsA(isA<EngineException>()),
      );
    });
  });
}
