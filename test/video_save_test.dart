import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_queue_store.dart';
import 'package:music_download_play_app/features/downloads/data/repositories/yt_dlp_video_save_repository.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';

void main() {
  test('mp4 선택자는 상한 이하 H.264+AAC를 먼저 찾고 합쳐진 형식으로 끝난다', () {
    final s = YtDlpVideoSaveRepository.selector(1080);
    expect(s, startsWith('bv*[height<=1080][vcodec^=avc1]+ba[ext=m4a]'));
    expect(s, endsWith('/b[height<=1080]/b'));
  });

  test('webm 선택자는 VP9+Opus 원본을 먼저 찾는다', () {
    final s = YtDlpVideoSaveRepository.selector(720, VideoFormat.webm);
    expect(s, startsWith('bv*[height<=720][ext=webm]+ba[ext=webm]'));
  });

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
