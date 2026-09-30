import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/library/domain/entities/library_sort.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';

Track _t(
  String id,
  String title, {
  String artist = '',
  String genre = '',
  int day = 1,
}) => Track(
  id: id,
  title: title,
  artist: artist,
  album: '',
  genre: genre,
  duration: const Duration(minutes: 3),
  addedAt: DateTime(2026, 1, day),
);

void main() {
  final tracks = [
    _t('1', 'b', artist: 'Z', genre: 'Rock', day: 1),
    _t('2', 'a', artist: 'Z', genre: 'pop', day: 3),
    _t('3', 'c', artist: 'A', genre: '', day: 2),
  ];

  test('이름순 · 추가일 최신순 · 아티스트순', () {
    expect(sortTracks(tracks, LibrarySort.name).map((t) => t.id), [
      '2',
      '1',
      '3',
    ]);
    expect(sortTracks(tracks, LibrarySort.added).map((t) => t.id), [
      '2',
      '3',
      '1',
    ]);
    expect(sortTracks(tracks, LibrarySort.artist).map((t) => t.id), [
      '3',
      '2',
      '1',
    ]);
  });

  test('원본 목록은 바뀌지 않는다', () {
    sortTracks(tracks, LibrarySort.name);
    expect(tracks.map((t) => t.id), ['1', '2', '3']);
  });

  test('장르별 묶음: 이름순(대소문자 무시), 장르 모름은 맨 뒤', () {
    final groups = groupByGenre(tracks);
    expect(groups.keys, ['pop', 'Rock', '']);
    expect(groups['Rock']!.single.id, '1');
  });
}
