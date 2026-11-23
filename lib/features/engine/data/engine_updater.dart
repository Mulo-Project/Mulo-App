import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/diagnostics/diag_notice.dart';
import '../domain/entities/engine_notice.dart';
import '../domain/repositories/engine_notices.dart';
import 'android_yt_dlp.dart';

/// 받기 엔진(yt-dlp)을 사용자가 몰라도 최신으로 유지한다.
///
/// - 앱을 켤 때마다 [checkOnLaunch]로 검사한다. 새 버전이 있고 인터넷이 될 때만 받는다.
///   인터넷이 없으면 조용히 건너뛰고 다음에 켤 때 다시 한다.
/// - 받기가 버전 때문에 실패하면 [onDownloadFailed]: 사용자에게 알리고(스낵바) 바로 한 번 업데이트한다.
/// - 실패해도 앱 안에 들어 있는 yt-dlp를 계속 쓰고, 사용자 화면에는 아무것도 띄우지 않는다.
/// - 로컬 엔진이 없는 빌드(lite)와 Android 밖에서는 아무것도 하지 않는다.
class EngineUpdater implements EngineNotices {
  EngineUpdater({required this._android, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// 받기가 실패해서 하는 업데이트를 이 간격 안에서는 다시 하지 않는다 (같은 실패의 반복 방지).
  static const failureRetryGap = Duration(hours: 1);

  final AndroidYtDlp _android;
  final DateTime Function() _now;
  final _notices = StreamController<EngineNotice>.broadcast();

  bool _running = false;
  DateTime? _lastFailureUpdate;

  @override
  Stream<EngineNotice> watch() => _notices.stream;

  /// yt-dlp가 "버전이 오래됐다"고 알려 주는 오류 문구인지.
  static bool looksOutdated(String message) {
    final m = message.toLowerCase();
    return const [
      'unable to extract',
      'latest version',
      'update yt-dlp',
      'please update',
      'nsig extraction failed',
    ].any(m.contains);
  }

  /// 앱을 켤 때 부른다. 기다리지 않아도 되고, 실패해도 예외를 던지지 않는다.
  Future<void> checkOnLaunch() async {
    if (!Platform.isAndroid) return;
    await _update();
  }

  /// 받기가 [message]로 실패했을 때 부른다. 버전 때문이면 알리고 업데이트한다.
  Future<void> onDownloadFailed(String message) async {
    if (!looksOutdated(message)) return;
    _log('받기가 버전 때문에 실패 → 알림 + 업데이트: ${message.split('\n').first}');
    _notices.add(EngineNotice.outdated);
    final last = _lastFailureUpdate;
    if (last != null && _now().difference(last) < failureRetryGap) return;
    _lastFailureUpdate = _now();
    await _update();
  }

  Future<void> _update() async {
    if (_running) return;
    _running = true;
    final watch = Stopwatch()..start();
    try {
      if (!await _android.isAvailable()) return;
      _log('업데이트 확인 시작');
      final version = await _android.update();
      _log('업데이트 확인 끝 version=$version ${watch.elapsedMilliseconds}ms');
    } on Object catch (e) {
      // 인터넷이 없거나 받지 못했다. 번들 yt-dlp를 계속 쓴다.
      _log('업데이트 실패(번들 yt-dlp 사용): $e ${watch.elapsedMilliseconds}ms');
    } finally {
      _running = false;
    }
  }

  /// 로그(`adb logcat -s flutter`의 `MuloEngine`)와, 디버그 빌드에서는 snackbar로 보인다.
  void _log(String message) {
    debugPrint('MuloEngine $message');
    DiagNotice.post('[engine] $message');
  }
}
