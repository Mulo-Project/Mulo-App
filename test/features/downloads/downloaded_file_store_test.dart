import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/downloaded_file_store.dart';

void main() {
  group('androidMediaType', () {
    test('MediaStore가 거절하는 webm은 ogg(.opus)로 등록한다', () {
      final t = PlatformDownloadedFileStore.androidMediaType(
        'weba',
        'audio/webm',
      );
      expect(t.extension, 'opus');
      expect(t.mime, 'audio/ogg');
    });

    test('받아 주는 형식은 그대로 둔다', () {
      final t = PlatformDownloadedFileStore.androidMediaType(
        'mp3',
        'audio/mpeg',
      );
      expect(t.extension, 'mp3');
      expect(t.mime, 'audio/mpeg');
    });
  });
}
