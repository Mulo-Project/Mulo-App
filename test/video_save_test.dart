import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/download_request_codec.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_options.dart';
import 'package:music_download_play_app/features/downloads/domain/entities/download_request.dart';

void main() {
  test('받기 요청의 영상 설정을 네이티브에 넘긴다', () {
    const r = DownloadRequest(
      title: 't',
      url: 'u',
      videoFormat: VideoFormat.webm,
      videoHeight: 480,
    );
    final sent = encodeDownloadRequest(r);
    expect(sent['videoFormat'], 'webm');
    expect(sent['videoHeight'], 480);
    final none = encodeDownloadRequest(
      const DownloadRequest(title: 't', url: 'u'),
    );
    expect(none.containsKey('videoFormat'), isFalse);
  });
}
