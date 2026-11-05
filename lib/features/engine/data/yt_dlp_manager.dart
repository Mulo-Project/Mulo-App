import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'android_yt_dlp.dart';

import '../domain/entities/engine_status.dart';
import '../domain/repositories/engine_manager.dart';

/// 데스크톱에서 yt-dlp 공식 릴리스를 앱 전용 폴더(`<앱 데이터>/engine`)에 받아 둔다.
/// 앱이 받은 파일이 없으면 PATH의 `yt-dlp`를 쓴다.
/// Android(full 빌드)는 APK 안의 yt-dlp를 쓰고, "설치"는 그 yt-dlp를 최신으로 올린다.
/// 올린 뒤 문제가 생기면 "삭제"(remove)가 업데이트한 것을 지워 APK에 들어 있던 버전으로 되돌린다.
class YtDlpManager implements EngineManager {
  YtDlpManager({this.releaseBase = _release, AndroidYtDlp? android})
    : _android = android ?? AndroidYtDlp();

  final AndroidYtDlp _android;

  static const _release =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download';

  final String releaseBase;

  static bool get _desktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static String get _assetName => Platform.isWindows
      ? 'yt-dlp.exe'
      : Platform.isMacOS
      ? 'yt-dlp_macos'
      : 'yt-dlp_linux';

  /// Android: 내장 yt-dlp는 파일을 지울 수 없어서, "삭제"하면 쓰지 않도록 꺼 둔다 ("설치"가 다시 켠다).
  static const _disabledKey = 'engine_disabled';

  Future<bool> _isDisabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_disabledKey) ??
          false;
    } on Object {
      return false;
    }
  }

  Future<void> _setDisabled(bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(
        _disabledKey,
        value,
      );
    } on Object {
      // 저장하지 못하면 그대로 켜 둔다.
    }
  }

  Future<File> _managedFile() async {
    final dir = await getApplicationSupportDirectory();
    final name = Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
    return File(
      '${dir.path}${Platform.pathSeparator}engine'
      '${Platform.pathSeparator}$name',
    );
  }

  /// 실행할 파일: 앱이 받은 것이 있으면 그 경로, 없으면 `yt-dlp`(PATH).
  Future<String> executablePath() async {
    if (!_desktop) return 'yt-dlp';
    final f = await _managedFile();
    return f.existsSync() ? f.path : 'yt-dlp';
  }

  @override
  Future<EngineStatus> status() async {
    if (Platform.isAndroid) {
      if (!await _android.isAvailable()) {
        return const EngineStatus(supported: false);
      }
      if (await _isDisabled()) {
        // 지워서 꺼 둔 상태: 설치하기 전에는 검색 · 받기를 막는다.
        return const EngineStatus(managed: true);
      }
      // 버전은 업데이트한 뒤에만 있다. 없으면 APK에 들어 있는 yt-dlp를 쓰는 중이다 (항상 쓸 수 있다).
      final version = await _android.version();
      return EngineStatus(
        installed: true,
        version: version,
        managed: true,
        // 업데이트한 적이 있으면 지우기 = 내장 버전으로 되돌리기, 없으면 지우기 = 끄기.
        removable: true,
        revertible: version != null,
      );
    }
    if (!_desktop) return const EngineStatus(supported: false);
    final exe = await executablePath();
    final managed = exe != 'yt-dlp';
    try {
      final r = await Process.run(exe, const ['--version']);
      if (r.exitCode == 0) {
        return EngineStatus(
          installed: true,
          version: (r.stdout as String).trim(),
          managed: managed,
          removable: managed,
        );
      }
    } on ProcessException {
      // 실행할 수 없으면 설치 안 됨.
    }
    // 받은 파일이 있어도 실행되지 않으면 지울 수 있게 둔다 (깨진 파일 정리).
    return EngineStatus(removable: managed);
  }

  @override
  Future<EngineStatus> remove() async {
    // 앱이 받은 파일만 지운다. PATH의 yt-dlp · Android 내장 엔진은 건드리지 않는다.
    if (Platform.isAndroid) {
      if (await _android.isAvailable()) {
        if (await _android.version() != null) {
          // 업데이트로 받은 yt-dlp를 지우면 APK에 들어 있던 버전으로 돌아간다.
          await _android.revert();
        } else {
          // 내장 yt-dlp는 지울 수 없으니 끈다.
          await _setDisabled(true);
        }
      }
    } else if (_desktop) {
      final target = await _managedFile();
      for (final f in [target, File('${target.path}.download')]) {
        if (f.existsSync()) await f.delete();
      }
    }
    return status();
  }

  @override
  Future<EngineStatus> install() async {
    if (Platform.isAndroid) {
      await _setDisabled(false);
      await _android.update();
      return status();
    }
    if (!_desktop) {
      throw UnsupportedError('engine install is desktop and Android only');
    }
    final target = await _managedFile();
    await target.parent.create(recursive: true);
    final tmp = File('${target.path}.download');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse('$releaseBase/$_assetName'));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('download failed: ${res.statusCode}');
      }
      final sink = tmp.openWrite();
      await res.pipe(sink);
    } finally {
      client.close(force: true);
    }
    if (!Platform.isWindows) await Process.run('chmod', ['+x', tmp.path]);
    if (target.existsSync()) await target.delete();
    await tmp.rename(target.path);
    final s = await status();
    if (!s.installed) {
      throw const FileSystemException('installed yt-dlp does not run');
    }
    return s;
  }
}
