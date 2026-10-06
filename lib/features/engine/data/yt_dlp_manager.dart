import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/entities/engine_status.dart';
import '../domain/repositories/engine_manager.dart';

/// 데스크톱에서 yt-dlp 공식 릴리스를 앱 전용 폴더(`<앱 데이터>/engine`)에 받아 둔다.
/// 앱이 받은 파일이 없으면 PATH의 `yt-dlp`를 쓴다.
class YtDlpManager implements EngineManager {
  YtDlpManager({this.releaseBase = _release});

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
        );
      }
    } on ProcessException {
      // 실행할 수 없으면 설치 안 됨.
    }
    return const EngineStatus();
  }

  @override
  Future<EngineStatus> install() async {
    if (!_desktop) {
      throw UnsupportedError('engine install is desktop only');
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
