import 'track.dart';

/// 보관함 정렬 기준.
enum LibrarySort {
  name,
  added,
  artist,

  /// 곡 수 많은 순 (묶음 탭에서만).
  count,
}

/// [sort] 기준으로 정렬한 새 목록 (원본은 그대로).
List<Track> sortTracks(List<Track> tracks, LibrarySort sort) {
  final list = [...tracks];
  switch (sort) {
    case LibrarySort.name || LibrarySort.count:
      list.sort((a, b) => a.title.compareTo(b.title));
    case LibrarySort.added:
      list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    case LibrarySort.artist:
      list.sort((a, b) {
        final byArtist = a.artist.compareTo(b.artist);
        return byArtist != 0 ? byArtist : a.title.compareTo(b.title);
      });
  }
  return list;
}

/// 장르별로 묶는다. 장르 이름순, 장르를 모르는 곡(빈 문자열)은 맨 뒤.
/// 묶음 안의 곡 순서는 [tracks] 순서를 지킨다.
Map<String, List<Track>> groupByGenre(List<Track> tracks) {
  final map = <String, List<Track>>{};
  for (final t in tracks) {
    map.putIfAbsent(t.genre.trim(), () => []).add(t);
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  return {for (final k in keys) k: map[k]!};
}

/// 묶음(아티스트 · 앨범 · 장르)을 [sort] 기준으로 정렬한 새 맵.
/// name: 이름순 (장르는 모르는 장르가 맨 뒤), count: 곡 많은 순, added: 가장 최근에 담은 곡이 있는 순.
/// 같으면 이름순. artist는 곡 정렬용이라 이름순과 같다.
Map<String, List<Track>> sortGroups(
  Map<String, List<Track>> groups,
  LibrarySort sort,
) {
  int byName(String a, String b) {
    if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  DateTime latest(List<Track> l) =>
      l.map((t) => t.addedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final keys = groups.keys.toList()
    ..sort((a, b) {
      final primary = switch (sort) {
        LibrarySort.count => groups[b]!.length.compareTo(groups[a]!.length),
        LibrarySort.added => latest(groups[b]!).compareTo(latest(groups[a]!)),
        _ => 0,
      };
      return primary != 0 ? primary : byName(a, b);
    });
  return {for (final k in keys) k: groups[k]!};
}
