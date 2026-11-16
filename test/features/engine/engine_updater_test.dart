import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/engine/data/android_yt_dlp.dart';
import 'package:music_download_play_app/features/engine/data/engine_updater.dart';
import 'package:music_download_play_app/features/engine/domain/entities/engine_notice.dart';

void main() {
  group('EngineUpdater.looksOutdated', () {
    test('yt-dlp가 버전이 오래됐다고 알리는 문구를 알아본다', () {
      expect(
        EngineUpdater.looksOutdated(
          'ERROR: [youtube] abc: Unable to extract player response',
        ),
        isTrue,
      );
      expect(
        EngineUpdater.looksOutdated('make sure you are using the latest version'),
        isTrue,
      );
    });

    test('그 밖의 실패는 버전 문제로 보지 않는다', () {
      expect(EngineUpdater.looksOutdated('네트워크에 닿지 못했어요'), isFalse);
      expect(EngineUpdater.looksOutdated(''), isFalse);
    });
  });

  group('EngineUpdater.onDownloadFailed', () {
    test('버전 때문에 실패하면 소식을 알린다', () async {
      final updater = EngineUpdater(android: AndroidYtDlp());
      final notices = <EngineNotice>[];
      final sub = updater.watch().listen(notices.add);

      await updater.onDownloadFailed('Unable to extract uploader id');
      await Future<void>.delayed(Duration.zero);
      expect(notices, [EngineNotice.outdated]);
      await sub.cancel();
    });

    test('버전과 상관없는 실패는 알리지 않는다', () async {
      final updater = EngineUpdater(android: AndroidYtDlp());
      final notices = <EngineNotice>[];
      final sub = updater.watch().listen(notices.add);

      await updater.onDownloadFailed('찾을 수 없는 주소예요');
      await Future<void>.delayed(Duration.zero);
      expect(notices, isEmpty);
      await sub.cancel();
    });

    test('Android가 아니면 업데이트 확인은 조용히 끝난다', () async {
      final updater = EngineUpdater(android: AndroidYtDlp());
      await updater.checkOnLaunch();
    });
  });
}
