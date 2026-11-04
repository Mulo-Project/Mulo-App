import 'dart:collection';

import '../../domain/entities/lyrics.dart';
import '../../domain/repositories/lyrics_repository.dart';

/// [LyricsRepository] 앞에 두는 메모리 캐시 (LRU).
///
/// 가사를 한 번 불러온 곡은 DB 조회 · 파일 읽기 · 음원 태그 읽기 · 파싱을 다시 하지 않는다.
/// 가사가 **없다는 결과**도 캐시한다. 없는 곡은 옆 `.lrc`와 파일 태그까지 뒤져서 가장 느리기 때문이다.
///
/// 비우는 때:
///  * 용량이 [maxEntries]곡 또는 [maxChars]자를 넘으면 가장 오래 안 쓴 곡부터 뺀다.
///  * 이 저장소로 `save` · `remove` 하면 그 곡 캐시를 바로 갱신한다 (앱의 가사 쓰기는 모두 이 저장소를 지난다).
///  * 곡 재생 주소가 바뀌면(파일 이동 등) 그 곡은 다시 읽는다.
///  * [clear]로 전부 비운다. 재생 목록이 바뀌어도 곡별 가사는 그대로라서 따로 비우지 않는다.
///
/// 캐시는 앱이 켜져 있는 동안만 산다. 앱 밖에서 옆 `.lrc`를 고친 경우는 다시 실행하면 반영된다.
class CachedLyricsRepository implements LyricsRepository {
  CachedLyricsRepository(
    this._inner, {
    this.maxEntries = 64,
    this.maxChars = 1000000,
  });

  final LyricsRepository _inner;
  final int maxEntries;
  final int maxChars;

  /// 삽입 순서 = 오래 안 쓴 순서. 읽을 때마다 맨 뒤로 옮긴다.
  final _entries = LinkedHashMap<String, _Entry>();
  final _inFlight = <String, Future<Lyrics?>>{};
  // 불러오는 도중 save · remove 가 끼면 늦게 온 옛 결과를 캐시에 넣지 않기 위한 표시.
  final _version = <String, int>{};
  int _chars = 0;

  @override
  Future<Lyrics?> load(String trackId, String trackUri) {
    final hit = _entries.remove(trackId);
    if (hit != null) {
      if (hit.uri == trackUri) {
        _entries[trackId] = hit;
        return Future.value(hit.lyrics);
      }
      _chars -= hit.size;
    }
    final key = '$trackId\u0000$trackUri';
    return _inFlight[key] ??= _read(trackId, trackUri, key);
  }

  Future<Lyrics?> _read(String trackId, String trackUri, String key) async {
    final started = _version[trackId] ?? 0;
    try {
      final lyrics = await _inner.load(trackId, trackUri);
      if ((_version[trackId] ?? 0) == started) {
        _put(trackId, _Entry(trackUri, lyrics));
      }
      return lyrics;
    } finally {
      _inFlight.remove(key);
    }
  }

  @override
  Future<Lyrics?> save(String trackId, String text) async {
    _invalidate(trackId);
    final lyrics = await _inner.save(trackId, text);
    _invalidate(trackId);
    return lyrics;
  }

  @override
  Future<void> remove(String trackId) async {
    _invalidate(trackId);
    await _inner.remove(trackId);
    _invalidate(trackId);
  }

  /// 캐시를 모두 비운다.
  void clear() {
    _entries.clear();
    _chars = 0;
    for (final id in _inFlight.keys.map((k) => k.split('\u0000').first)) {
      _bump(id);
    }
  }

  void _invalidate(String trackId) {
    _bump(trackId);
    final old = _entries.remove(trackId);
    if (old != null) _chars -= old.size;
  }

  void _bump(String trackId) =>
      _version[trackId] = (_version[trackId] ?? 0) + 1;

  void _put(String trackId, _Entry entry) {
    final old = _entries.remove(trackId);
    if (old != null) _chars -= old.size;
    _entries[trackId] = entry;
    _chars += entry.size;
    // 방금 넣은 곡 하나는 지키고, 용량이 넘는 동안 오래된 곡부터 뺀다.
    while (_entries.length > 1 &&
        (_entries.length > maxEntries || _chars > maxChars)) {
      final oldest = _entries.keys.first;
      _chars -= _entries.remove(oldest)!.size;
    }
  }
}

class _Entry {
  _Entry(this.uri, this.lyrics) : size = lyrics?.raw.length ?? 0;

  final String uri;
  final Lyrics? lyrics;
  final int size;
}
