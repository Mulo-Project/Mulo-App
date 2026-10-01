import '../../features/library/domain/entities/track.dart';

/// UI 퍼블리싱용 가짜 데이터 (검색 · 다운로드 화면, 테스트). 보관함 · 재생목록 · 홈은 실제 DB를 쓰고,
/// 디버그 빌드에서는 이 곡들을 `sample_seeder.dart`가 DB에 넣어 준다. 실제 곡 · URL을 쓰지 않는다 (저작권).
/// 기능이 연결되면 각 기능의 리포지토리로 대체하고 이 파일은 지운다.
abstract final class SampleData {
  static final tracks = <Track>[
    Track(
      id: 't01',
      genre: 'Pop',
      uri: 'sample://t01',
      title: 'Midnight Signal',
      artist: 'Neon Harbor',
      album: 'Afterglow',
      duration: Duration(minutes: 3, seconds: 42),
      addedAt: DateTime(2026, 9, 12),
    ),
    Track(
      id: 't02',
      genre: 'Indie',
      uri: 'sample://t02',
      title: 'Paper Satellites',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 4, seconds: 5),
      addedAt: DateTime(2026, 9, 3),
    ),
    Track(
      id: 't03',
      genre: 'Electronic',
      uri: 'sample://t03',
      title: 'Slow Static',
      artist: 'Neon Harbor',
      album: 'Afterglow',
      duration: Duration(minutes: 2, seconds: 58),
      addedAt: DateTime(2026, 9, 9),
    ),
    Track(
      id: 't04',
      genre: 'Pop',
      uri: 'sample://t04',
      title: 'Glasshouse',
      artist: 'Coral Drive',
      album: 'Tidal',
      duration: Duration(minutes: 3, seconds: 21),
      addedAt: DateTime(2026, 9, 7),
    ),
    Track(
      id: 't05',
      genre: 'Ambient',
      uri: 'sample://t05',
      title: 'Violet Hour',
      artist: 'Mono Garden',
      album: 'Bloom',
      duration: Duration(minutes: 5, seconds: 12),
      addedAt: DateTime(2026, 9, 1),
    ),
    Track(
      id: 't06',
      genre: 'Electronic',
      uri: 'sample://t06',
      title: 'Lime Light Runner',
      artist: 'Coral Drive',
      album: 'Tidal',
      duration: Duration(minutes: 3, seconds: 3),
      addedAt: DateTime(2026, 9, 11),
    ),
    Track(
      id: 't07',
      genre: 'Indie',
      uri: 'sample://t07',
      title: 'Northbound',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 4, seconds: 44),
      addedAt: DateTime(2026, 9, 5),
    ),
    Track(
      id: 't08',
      genre: 'Ambient',
      uri: 'sample://t08',
      title: 'Echo Chamber',
      artist: 'Mono Garden',
      album: 'Bloom',
      duration: Duration(minutes: 3, seconds: 36),
      addedAt: DateTime(2026, 9, 10),
    ),
    Track(
      id: 't09',
      genre: 'Lo-fi',
      uri: 'sample://t09',
      title: 'Quiet Engines',
      artist: 'Static Bloom',
      album: 'Low Light',
      duration: Duration(minutes: 2, seconds: 47),
      addedAt: DateTime(2026, 9, 2),
    ),
    Track(
      id: 't10',
      genre: 'Lo-fi',
      uri: 'sample://t10',
      title: 'Afterimage',
      artist: 'Static Bloom',
      album: 'Low Light',
      duration: Duration(minutes: 3, seconds: 59),
      addedAt: DateTime(2026, 9, 8),
    ),
    Track(
      id: 't11',
      genre: 'Pop',
      uri: 'sample://t11',
      title: 'Harbor Lights',
      artist: 'Neon Harbor',
      album: 'Nightline',
      duration: Duration(minutes: 4, seconds: 18),
      addedAt: DateTime(2026, 9, 6),
    ),
    Track(
      id: 't12',
      genre: 'Indie',
      uri: 'sample://t12',
      title: 'Soft Machines',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 3, seconds: 27),
      addedAt: DateTime(2026, 9, 4),
    ),
  ];

  static const playlists = <(String name, int count)>[
    ('Late Night Drive', 24),
    ('Focus', 18),
    ('Workout Mix', 32),
    ('Rainy Day', 12),
  ];

  static const engineCurrent = '2026.08.12';
  static const engineLatest = '2026.09.20';
  static const savePath = '/storage/emulated/0/Music/MusicApp';
  static const appVersion = '1.0.0';
}
