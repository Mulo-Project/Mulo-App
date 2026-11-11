import 'dart:io';

import '../../../../core/config/default_video_folder.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/repositories/video_save_repository.dart';
import '../datasources/cover_tag_writer.dart';
import '../datasources/downloaded_file_store.dart';

/// 영상(+소리) 하나를 받아 `<dir>/<stem>.<extension>`으로 합쳐 두는 일 (네이티브 yt-dlp 엔진, 못 받으면 예외).
typedef VideoFetch =
    Future<void> Function({
      required String url,
      required int maxHeight,
      required String extension,
      required String dir,
      required String stem,
      void Function(double progress)? onProgress,
    });

/// 네이티브 yt-dlp가 영상과 소리를 받아 합치고(APK에 든 ffmpeg 사용), 그 파일을 `Movies/Mulo`에 저장한다.
///
/// 형식별 선택 · 합치기 인자는 네이티브가 가진다. 오래 걸리는 일이라 네이티브가 검색 · 주소 읽기와 같은 실행 줄을 쓰지 않는다.
class YtDlpVideoSaveRepository implements VideoSaveRepository {
  YtDlpVideoSaveRepository({
    required this.fetch,
    required this.available,
    required this.store,
    required this.tempDir,
    this.tags,
  });

  final VideoFetch fetch;
  final Future<bool> Function() available;
  final DownloadedFileStore store;
  final Future<Directory> Function() tempDir;

  /// 받은 영상에 제목 · 아티스트 · 커버 태그를 쓴다 (없거나 못 쓰면 태그 없이 저장).
  final CoverTagWriter? tags;

  @override
  Future<bool> isAvailable() => available();

  @override
  Future<String> save(
    VideoSaveRequest request, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await tempDir();
    final stem = 'video_${DateTime.now().microsecondsSinceEpoch}';
    File? output;
    try {
      await fetch(
        url: request.url,
        maxHeight: request.maxHeight,
        extension: request.format.extension,
        dir: dir.path,
        stem: stem,
        onProgress: onProgress,
      );
      output = await _find(dir, stem, request.format.extension);
      if (output == null) throw const VideoSaveException('no output file');
      // 태그를 못 써도 영상은 그대로 저장한다.
      await tags?.embed(
        output,
        extension: request.format.extension,
        cover: request.cover,
        thumbnailUrl: request.thumbnailUrl,
        title: request.title,
        artist: request.artist,
        album: request.album,
        genre: request.genre,
        lyrics: request.lyrics,
        color: request.color,
      );
      final saved = await store.save(
        output,
        folder: request.folder.isEmpty ? defaultVideoFolder() : request.folder,
        name: safeName(request.title),
        extension: request.format.extension,
        mime: request.format.mime,
        title: request.title,
        artist: request.artist,
      );
      return saved.uri;
    } on VideoSaveException {
      rethrow;
    } on Object catch (e) {
      throw VideoSaveException('$e');
    } finally {
      await _cleanup(dir, stem);
    }
  }

  /// 합쳐진 영상 파일 (없거나 비었으면 null).
  static Future<File?> _find(Directory dir, String stem, String ext) async {
    final mp4 = File('${dir.path}${Platform.pathSeparator}$stem.$ext');
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
