import 'dart:io';

import 'android_yt_dlp.dart';

import '../domain/entities/engine_status.dart';
import '../domain/repositories/engine_manager.dart';

/// Android(full 빌드)에서 APK 안의 yt-dlp를 관리한다. "설치"는 그 yt-dlp를 최신으로 올린다.
/// lite 빌드와 Android 밖에서는 지원하지 않는다 ([EngineStatus.supported]가 false).
class YtDlpManager implements EngineManager {
  YtDlpManager({AndroidYtDlp? android}) : _android = android ?? AndroidYtDlp();

  final AndroidYtDlp _android;

  @override
  Future<EngineStatus> status() async {
    if (!Platform.isAndroid || !await _android.isAvailable()) {
      return const EngineStatus(supported: false);
    }
    // yt-dlp는 APK에 들어 있어 항상 쓸 수 있다. 버전을 읽으면 yt-dlp를 켜야 해서
    // 화면을 열 때마다 하지 않는다 (검색 · 설정은 켜지 않고도 열려야 한다).
    return const EngineStatus(installed: true, managed: true);
  }

  @override
  Future<EngineStatus> install() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('engine install is Android only');
    }
    await _android.update();
    return status();
  }
}
