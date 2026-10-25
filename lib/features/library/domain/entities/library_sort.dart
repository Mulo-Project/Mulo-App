import 'track.dart';

/// 보관함 정렬 기준.
enum LibrarySort {
  name,
  added,
  artist,

  /// 곡 수 많은 순 (묶음 탭에서만).
  count,
}

/// 기준마다 처음 보여 줄 방향: 이름 · 아티스트는 오름차순(가나다), 담은 순 · 곡 수는 내림차순(최근 · 많은 것이 위).
bool defaultAscending(LibrarySort sort) =>
    sort == LibrarySort.name || sort == LibrarySort.artist;

/// [sort] 기준으로 정렬한 새 목록 (원본은 그대로).
/// [ascending]이 null이면 [defaultAscending]. 오름차순은 이름 가나다 · 오래된 것부터.
List<Track> sortTracks(
  List<Track> tracks,
  LibrarySort sort, {
  bool? ascending,
}) {
  final asc = ascending ?? defaultAscending(sort);
  final list = [...tracks];
  int dir(int c) => asc ? c : -c;
  switch (sort) {
    case LibrarySort.name || LibrarySort.count:
      list.sort((a, b) => dir(a.title.compareTo(b.title)));
    case LibrarySort.added:
      list.sort((a, b) => dir(a.addedAt.compareTo(b.addedAt)));
    case LibrarySort.artist:
      list.sort((a, b) {
        final byArtist = a.artist.compareTo(b.artist);
        return byArtist != 0 ? dir(byArtist) : dir(a.title.compareTo(b.title));
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
/// [ascending]이 null이면 [defaultAscending]. 이름이 없는 묶음은 방향과 상관없이 맨 뒤.
Map<String, List<Track>> sortGroups(
  Map<String, List<Track>> groups,
  LibrarySort sort, {
  bool? ascending,
}) {
  final asc = ascending ?? defaultAscending(sort);
  int dir(int c) => asc ? c : -c;
  int byName(String a, String b) {
    if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  DateTime latest(List<Track> l) =>
      l.map((t) => t.addedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final keys = groups.keys.toList()
    ..sort((a, b) {
      final primary = switch (sort) {
        LibrarySort.count => dir(
          groups[a]!.length.compareTo(groups[b]!.length),
        ),
        LibrarySort.added => dir(
          latest(groups[a]!).compareTo(latest(groups[b]!)),
        ),
        _ => 0,
      };
      if (primary != 0) return primary;
      // 이름순 기준일 때만 방향을 따르고, 다른 기준의 동점은 늘 이름 오름차순.
      final named = byName(a, b);
      final nameSort = sort == LibrarySort.name || sort == LibrarySort.artist;
      return nameSort && a.isNotEmpty && b.isNotEmpty ? dir(named) : named;
    });
  return {for (final k in keys) k: groups[k]!};
}
