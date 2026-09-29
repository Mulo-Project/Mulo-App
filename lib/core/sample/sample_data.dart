import '../../features/library/domain/track.dart';

/// UI 퍼블리싱용 가짜 데이터. 실제 곡 · URL을 쓰지 않는다 (저작권).
/// 기능이 연결되면 각 기능의 리포지토리로 대체하고 이 파일은 지운다.
abstract final class SampleData {
  static const tracks = <Track>[
    Track(
      id: 't01',
      title: 'Midnight Signal',
      artist: 'Neon Harbor',
      album: 'Afterglow',
      duration: Duration(minutes: 3, seconds: 42),
      addedOrder: 12,
    ),
    Track(
      id: 't02',
      title: 'Paper Satellites',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 4, seconds: 5),
      addedOrder: 3,
    ),
    Track(
      id: 't03',
      title: 'Slow Static',
      artist: 'Neon Harbor',
      album: 'Afterglow',
      duration: Duration(minutes: 2, seconds: 58),
      addedOrder: 9,
    ),
    Track(
      id: 't04',
      title: 'Glasshouse',
      artist: 'Coral Drive',
      album: 'Tidal',
      duration: Duration(minutes: 3, seconds: 21),
      addedOrder: 7,
    ),
    Track(
      id: 't05',
      title: 'Violet Hour',
      artist: 'Mono Garden',
      album: 'Bloom',
      duration: Duration(minutes: 5, seconds: 12),
      addedOrder: 1,
    ),
    Track(
      id: 't06',
      title: 'Lime Light Runner',
      artist: 'Coral Drive',
      album: 'Tidal',
      duration: Duration(minutes: 3, seconds: 3),
      addedOrder: 11,
    ),
    Track(
      id: 't07',
      title: 'Northbound',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 4, seconds: 44),
      addedOrder: 5,
    ),
    Track(
      id: 't08',
      title: 'Echo Chamber',
      artist: 'Mono Garden',
      album: 'Bloom',
      duration: Duration(minutes: 3, seconds: 36),
      addedOrder: 10,
    ),
    Track(
      id: 't09',
      title: 'Quiet Engines',
      artist: 'Static Bloom',
      album: 'Low Light',
      duration: Duration(minutes: 2, seconds: 47),
      addedOrder: 2,
    ),
    Track(
      id: 't10',
      title: 'Afterimage',
      artist: 'Static Bloom',
      album: 'Low Light',
      duration: Duration(minutes: 3, seconds: 59),
      addedOrder: 8,
    ),
    Track(
      id: 't11',
      title: 'Harbor Lights',
      artist: 'Neon Harbor',
      album: 'Nightline',
      duration: Duration(minutes: 4, seconds: 18),
      addedOrder: 6,
    ),
    Track(
      id: 't12',
      title: 'Soft Machines',
      artist: 'Lumen Field',
      album: 'Orbit Tapes',
      duration: Duration(minutes: 3, seconds: 27),
      addedOrder: 4,
    ),
  ];

  static const playlists = <(String name, int count)>[
    ('Late Night Drive', 24),
    ('Focus', 18),
    ('Workout Mix', 32),
    ('Rainy Day', 12),
  ];

  static const librarySize = '9.4 GB';
  static const engineCurrent = '2026.08.12';
  static const engineLatest = '2026.09.20';
  static const savePath = '/storage/emulated/0/Music/MusicApp';
  static const appVersion = '1.0.0';
}
