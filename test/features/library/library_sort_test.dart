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

  test('방향을 바꾸면 곡 순서가 뒤집힌다', () {
    List<String> ids(LibrarySort s, bool asc) =>
        sortTracks(tracks, s, ascending: asc).map((t) => t.id).toList();
    expect(ids(LibrarySort.name, false), ['3', '1', '2']);
    expect(ids(LibrarySort.added, true), ['1', '3', '2']);
    expect(ids(LibrarySort.artist, false), ['1', '2', '3']);
  });

  test('묶음도 방향을 따르고 장르를 모르는 묶음은 늘 맨 뒤', () {
    final groups = groupByGenre(tracks);
    expect(sortGroups(groups, LibrarySort.name).keys.toList(), [
      'pop',
      'Rock',
      '',
    ]);
    expect(
      sortGroups(groups, LibrarySort.name, ascending: false).keys.toList(),
      ['Rock', 'pop', ''],
    );
  });

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
