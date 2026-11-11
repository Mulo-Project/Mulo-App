import 'package:flutter/foundation.dart' show debugPrint;

import '../../../covers/domain/entities/cover_art.dart';
import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../../downloads/data/datasources/native_tags.dart';
import '../../domain/repositories/track_tag_repository.dart';

/// 곡 파일([uri])의 태그를 쓴다. Dart는 값과 주소만 네이티브(`music_app/tags`)에 한 번 넘긴다.
/// 형식 구분 · 복사 · 태그 쓰기 · 덮어쓰기 · 동의 창은 네이티브가 한다 (`TagChannel`).
///
/// 결과로 "쓸 수 없는 곡"과 "쓰려다 실패"를 가른다 (네이티브가 알려 준다):
/// 쓰지 않는 곡(모르는 형식 · ffmpeg 없음 · 파일 접근 불가)은 [TagWriteResult.unsupported].
class TrackTagSource {
  TrackTagSource({
    CoverTagWriter writer = const CoverTagWriter(),
    NativeTags tags = const NativeTags(),
  }) : _writer = writer,
       _tags = tags;

  final CoverTagWriter _writer;
  final NativeTags _tags;

  Future<TagWriteResult> write(
    String uri, {
    required String? title,
    required String? artist,
    required String? album,
    required String? genre,
    String? lyrics,
    CoverArt? cover,
    int? color,
    bool interactive = false,
  }) async {
    if (uri.isEmpty) return TagWriteResult.unsupported;
    final status = await _writer.write(
      uri,
      cover: cover,
      color: color,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      lyrics: lyrics,
      // 사용자가 직접 한 저장이면 쓸 권한이 없을 때 시스템 동의 창을 띄운다.
      ask: interactive,
    );
    debugPrint('MuloTag write ${status.name} lyrics=${lyrics?.length} cover=${cover != null}');
    return switch (status) {
      NativeTagStatus.written => TagWriteResult.written,
      NativeTagStatus.failed => TagWriteResult.failed,
      NativeTagStatus.denied => TagWriteResult.denied,
      NativeTagStatus.unsupported => TagWriteResult.unsupported,
    };
  }

  /// 곡 파일에 쓸 수 있는지 확인하고, 못 쓰면 시스템 동의 창을 띄운다 (가사 편집 화면에 들어갈 때).
  Future<bool> ensureWriteAccess(String uri) => _tags.ensure(uri);
}
