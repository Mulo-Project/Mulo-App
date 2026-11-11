import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_queue_store.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/yt_dlp_video_save_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';

void main() {
  test('파일 이름에서 못 쓰는 글자를 뺀다', () {
    expect(YtDlpVideoSaveRepository.safeName('a/b: c*?"<>|d'), 'a b c d');
    expect(YtDlpVideoSaveRepository.safeName('  '), 'video');
    expect(YtDlpVideoSaveRepository.safeName('가' * 150).length, 100);
  });

  test('받기 요청의 영상 설정이 대기열 저장을 거쳐도 그대로다', () {
    const r = DownloadRequest(
      title: 't',
      url: 'u',
      videoFormat: VideoFormat.webm,
      videoHeight: 480,
    );
    final back = decodeDownloadRequest(encodeDownloadRequest(r));
    expect(back.videoFormat, VideoFormat.webm);
    expect(back.videoHeight, 480);
    final none = decodeDownloadRequest(
      encodeDownloadRequest(const DownloadRequest(title: 't', url: 'u')),
    );
    expect(none.videoFormat, isNull);
  });
}
