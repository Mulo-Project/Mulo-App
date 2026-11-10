import 'dart:io';

import '../../domain/repositories/video_save_repository.dart';
import '../datasources/downloaded_file_store.dart';

/// yt-dlp 실행 하나 (Android 로컬 엔진의 `run`과 같은 모양).
typedef VideoRun =
    Future<({int exitCode, String stdout, String stderr})> Function(
      String executable,
      List<String> args, {
      Duration timeout,
      bool background,
    });

/// yt-dlp가 영상과 소리를 받아 mp4로 합치고(APK에 든 ffmpeg 사용), 그 파일을 `Movies/Mulo`에 저장한다.
///
/// 영상 · 소리가 따로 오는 스트림(720p 이상)은 yt-dlp가 합친다. 오래 걸리는 일이라
/// 검색 · 주소 읽기와 같은 실행 줄을 쓰지 않는 `background`로 돌린다.
class YtDlpVideoSaveRepository implements VideoSaveRepository {
  YtDlpVideoSaveRepository({
    required this.run,
    required this.available,
    required this.store,
    required this.tempDir,
    this.timeout = const Duration(minutes: 30),
  });

  final VideoRun run;
  final Future<bool> Function() available;
  final DownloadedFileStore store;
  final Future<Directory> Function() tempDir;
  final Duration timeout;

  /// 화질 상한 이하에서 H.264 영상 + AAC 소리를 먼저 찾는다(다시 인코딩 없이 mp4로 합쳐진다).
  /// 없으면 아무 코덱, 그래도 없으면 영상 · 소리가 합쳐진 형식.
  static String selector(int h) =>
      'bv*[height<=$h][vcodec^=avc1]+ba[ext=m4a]/bv*[height<=$h]+ba/'
      'b[height<=$h]/b';

  @override
  Future<bool> isAvailable() => available();

  @override
  Future<void> save(VideoSaveRequest request) async {
    final dir = await tempDir();
    final stem = 'video_${DateTime.now().microsecondsSinceEpoch}';
    File? output;
    try {
      final r = await run(
        'yt-dlp',
        [
          '-f',
          selector(request.maxHeight),
          '--merge-output-format',
          'mp4',
          '--no-playlist',
          '--no-warnings',
          '-o',
          '${dir.path}${Platform.pathSeparator}$stem.%(ext)s',
          request.url,
        ],
        timeout: timeout,
        background: true,
      );
      if (r.exitCode != 0) throw VideoSaveException(r.stderr.trim());
      output = await _find(dir, stem);
      if (output == null) throw const VideoSaveException('no output file');
      await store.save(
        output,
        folder: 'Movies/Mulo',
        name: safeName(request.title),
        extension: 'mp4',
        mime: 'video/mp4',
        title: request.title,
        artist: request.artist,
      );
    } on VideoSaveException {
      rethrow;
    } on Object catch (e) {
      throw VideoSaveException('$e');
    } finally {
      await _cleanup(dir, stem);
    }
  }

  /// 합쳐진 mp4 (없거나 비었으면 null).
  static Future<File?> _find(Directory dir, String stem) async {
    final mp4 = File('${dir.path}${Platform.pathSeparator}$stem.mp4');
    return await mp4.exists() && await mp4.length() > 0 ? mp4 : null;
  }

  /// 받다 만 조각 · 합치기 전 파일을 지운다.
  static Future<void> _cleanup(Directory dir, String stem) async {
    try {
      await for (final e in dir.list()) {
        if (e is File && e.uri.pathSegments.last.startsWith(stem)) {
          await e.delete();
        }
      }
    } on Object {
      // 임시 폴더라 못 지워도 괜찮다.
    }
  }

  /// 파일 이름에 못 쓰는 글자를 뺀다. 비면 `video`.
  static String safeName(String title) {
    final s = title
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cut = s.length > 100 ? s.substring(0, 100).trim() : s;
    return cut.isEmpty ? 'video' : cut;
  }
}
