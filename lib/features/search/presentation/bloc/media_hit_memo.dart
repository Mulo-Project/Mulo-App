import '../../domain/entities/media_info.dart';

/// 상세 화면에서 이미 자세히 읽은 곡 정보를 잠깐 기억한다. 같은 곡의 상세를 다시 열면
/// 처음부터 채워진 채로 보여 주고 다시 읽지 않는다 (앱 전체에서 하나, 앱을 끄면 사라진다).
class MediaHitMemo {
  MediaHitMemo({
    this.keepFor = const Duration(hours: 1),
    this.maxEntries = 100,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration keepFor;
  final int maxEntries;
  final DateTime Function() _now;
  final _entries = <String, ({MediaHit hit, DateTime at})>{};

  /// 기억한 곡 정보. 없거나 오래됐으면 null.
  MediaHit? get(String url) {
    final e = _entries[url];
    if (e == null) return null;
    if (_now().difference(e.at) >= keepFor) {
      _entries.remove(url);
      return null;
    }
    return e.hit;
  }

  void put(String url, MediaHit hit) {
    _entries.remove(url);
    _entries[url] = (hit: hit, at: _now());
    // 오래된 것부터 버린다 (Map은 넣은 순서를 지킨다).
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }
}
