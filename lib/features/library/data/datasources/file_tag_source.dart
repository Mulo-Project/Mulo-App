import '../../../downloads/data/datasources/cover_tag_writer.dart';
import '../../../downloads/data/datasources/native_tags.dart';
import '../../domain/entities/file_tags.dart';

/// 곡 파일([uri])의 태그를 읽는다 ([TrackTagSource]의 반대 방향). 형식 구분 · 복사 · 읽기는 네이티브가 하고
/// (`music_app/tags`의 `read`), Dart는 돌아온 값(소문자 키)을 앱 값으로 옮길 뿐이다.
class FileTagSource {
  FileTagSource([this._tags = const NativeTags()]);

  final NativeTags _tags;

  /// 임시 진단: 이번에 읽은 곡들의 결과를 종류별로 센다 ([takeSummary]로 꺼내며 비운다).
  static final _outcomes = <String, int>{};

  static void _count(String key) => _outcomes[key] = (_outcomes[key] ?? 0) + 1;

  /// "mp3 ok 3 · audio/ogg unsupported 1" 같은 한 줄. 읽은 게 없으면 빈 문자열.
  static String takeSummary() {
    final text = _outcomes.entries.map((e) => '${e.key} ${e.value}').join(' · ');
    _outcomes.clear();
    return text;
  }

  /// 지원하지 않는 형식 · 태그 없음은 [FileTags.none], 파일을 못 읽으면 null.
  Future<FileTags?> read(String uri) async {
    if (uri.isEmpty) return null;
    final r = await _tags.read(uri);
    switch (r.status) {
      case 'ok':
        final tags = parse(r.tags);
        _count(tags.isEmpty ? 'tag empty' : 'ok');
        return tags;
      case 'unsupported':
        _count('unsupported');
        return FileTags.none;
      default:
        _count('read failed');
        return null;
    }
  }

  /// 읽은 태그(소문자 키)를 앱 값으로. 앱이 쓴 사용자 정의 칸(`COVER_*`)도 함께 읽는다.
  static FileTags parse(Map<String, String> tags) {
    final extra = parseCoverExtra(tags);
    return FileTags(
      title: _clean(tags['title']),
      artist: _clean(tags['artist']),
      album: _clean(tags['album']),
      genre: _clean(tags['genre']),
      coverSource: extra.source,
      coverTransform: extra.transform,
      coverColor: extra.color,
    );
  }

  static String _clean(String? v) => v?.trim() ?? '';
}
