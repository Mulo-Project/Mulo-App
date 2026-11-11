import 'dart:io';

import '../../../../core/cache/cached_web_image.dart';
import '../../../covers/domain/entities/cover_art.dart';
import 'native_tags.dart';

/// 곡 파일의 태그에 제목 · 커버 등을 넣는다 (다른 음악 앱에서도 보이도록).
///
/// 이 클래스는 형식을 모른다: 커버 원본 이미지 파일을 구해(앱 이미지 캐시) 값과 함께 네이티브(`NativeTags`)에 넘길 뿐이고,
/// 정사각형으로 자르기 · 형식 구분 · 태그 쓰기는 모두 네이티브가 한다.
class CoverTagWriter {
  const CoverTagWriter({this.tags = const NativeTags()});

  final NativeTags tags;

  /// 마지막 쓰기에서 커버 원본을 어떻게 구했는지 (진단용).
  static String lastCoverNote = '';

  /// [file]에 쓴다 (받은 파일). [extension]은 파일의 확장자 힌트. 썼으면 true, 아니면 false (파일은 그대로).
  Future<bool> embed(
    File file, {
    required String extension,
    CoverArt? cover,
    String? thumbnailUrl,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    int? color,
  }) async => await write(
        file.path,
        extension: extension,
        cover: cover,
        thumbnailUrl: thumbnailUrl,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        lyrics: lyrics,
        color: color,
      ) ==
      NativeTagStatus.written;

  /// [target](`content://` 주소 또는 경로)에 쓰고 결과를 돌려준다. 값이 하나도 없으면 [NativeTagStatus.failed].
  /// 커버를 못 구해도 글 정보는 쓴다. 빈 글은 쓰지 않는다.
  Future<NativeTagStatus> write(
    String target, {
    String? extension,
    CoverArt? cover,
    String? thumbnailUrl,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? lyrics,
    int? color,
    bool ask = false,
  }) async {
    try {
      final source = await _sourceFile(cover, thumbnailUrl);
      lastCoverNote = source == null
          ? 'cover: no image (path=${cover?.path != null}, url=${(cover?.url ?? thumbnailUrl) != null})'
          : 'cover: ${source.lengthSync()}B source';
      String? text(String? v) => v == null || v.trim().isEmpty ? null : v;
      final values = <String, String>{
        'title': ?text(title),
        'artist': ?text(artist),
        'album': ?text(album),
        'genre': ?text(genre),
        'lyrics': ?text(lyrics),
        // 앱이 읽어 커버 편집 상태를 되살리는 사용자 정의 태그 (COVER_SOURCE 등). 다른 플레이어는 무시한다.
        ...coverExtra(color),
      };
      return await tags.write(
        target,
        extension: extension,
        values: values,
        cover: source == null
            ? null
            : (
                path: source.path,
                transform: cover?.transform ?? CoverTransform.identity,
              ),
        ask: ask,
      );
    } on Object catch (e) {
      NativeTags.lastError = '$e';
      return NativeTagStatus.failed;
    }
  }

  static Future<File?> _sourceFile(
    CoverArt? cover,
    String? thumbnailUrl,
  ) async {
    final path = cover?.path;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      return file.existsSync() ? file : null;
    }
    final url = cover?.url ?? thumbnailUrl;
    if (url == null || url.isEmpty) return null;
    return CachedWebImage.localCopy(url);
  }
}

/// [coverExtra]로 쓴 `COVER_COLOR`를 되읽는다 (키는 대소문자 구분 없이). 없거나 깨졌으면 null.
int? parseCoverColor(Map<String, String> tags) {
  for (final e in tags.entries) {
    if (e.key.toUpperCase() != 'COVER_COLOR') continue;
    // ID3 사용자 정의 칸은 값 앞에 눈에 안 보이는 글자(BOM · 제어 문자)가 붙어 올 수 있다.
    final v = e.value.replaceAll(
      RegExp(r'^[\u0000-\u0020\uFEFF\uFFFE]+|[\u0000-\u0020\uFEFF\uFFFE]+$'),
      '',
    );
    if (v.isNotEmpty) return int.tryParse(v, radix: 16);
  }
  return null;
}

/// 앱 전용으로 파일에 남기는 사용자 정의 태그: 커버에서 뽑은 색. 커버 그림은 표준 칸에 이미지로 들어가므로
/// 원본 주소 · 확대 · 위치는 쓰지 않는다. 값이 없으면 그 칸은 쓰지 않는다.
Map<String, String> coverExtra(int? color) => {
  if (color != null) 'COVER_COLOR': color.toRadixString(16).padLeft(8, '0'),
};
