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
    // 버전은 업데이트한 뒤에만 있다. 없으면 APK에 들어 있는 yt-dlp를 쓰는 중이다 (항상 쓸 수 있다).
    final version = await _android.version();
    return EngineStatus(installed: true, version: version, managed: true);
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
