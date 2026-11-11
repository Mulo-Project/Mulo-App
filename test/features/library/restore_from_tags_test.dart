import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/covers/domain/entities/cover_art.dart';
import 'package:music_download_play_app/features/downloads/data/datasources/cover_tag_writer.dart';
import 'package:music_download_play_app/features/library/data/datasources/file_tag_source.dart';
import 'package:music_download_play_app/features/library/domain/entities/file_tags.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';
import 'package:music_download_play_app/features/library/domain/usecases/library_usecases.dart';

import '../../helpers/fakes.dart';

Track _track(String id, {TrackSource source = TrackSource.device}) => Track(
  id: id,
  title: '파일이름 $id',
  artist: '',
  album: '',
  duration: Duration.zero,
  uri: 'content://$id',
  addedAt: DateTime(2026, 10, 22),
  source: source,
);

class _Reader implements FileTagRepository {
  _Reader(this.byUri);

  /// 값이 null이면 읽기 실패.
  final Map<String, FileTags?> byUri;
  final reads = <String>[];

  @override
  Future<FileTags?> read(Track track) async {
    reads.add(track.id);
    return byUri[track.uri];
  }

  @override
  String takeSummary() => '';
}

class _Done implements TagRestoreStore {
  final done = <String>{};

  @override
  Future<Set<String>> loadDone() async => {...done};

  @override
  Future<void> markDone(Iterable<String> trackIds) async =>
      done.addAll(trackIds);
}

void main() {
  group('RestoreFromFileTags', () {
    test('태그의 정보 · 커버 편집 상태로 DB를 채우고, 태그에 없는 칸은 그대로 둔다', () async {
      final library = FakeLibraryRepository([_track('a')]);
      final covers = MemoryCoverRepository();
      final colors = MemoryCoverColorRepository();
      final done = _Done();
      final useCase = RestoreFromFileTags(
        library,
        covers,
        colors,
        _Reader({
          'content://a': const FileTags(
            title: ' 제목 ',
            artist: '가수',
            coverSource: 'https://img/x.jpg',
            coverTransform: CoverTransform(scale: 2, dx: .1, dy: -.2),
            coverColor: 0xFF112233,
          ),
        }),
        done,
      );

      expect(await useCase(const NoParams()), 1);
      final t = (await library.watchTracks().first).single;
      expect([t.title, t.artist, t.album], ['제목', '가수', '']);
      expect(covers.saved['track:a']!.url, 'https://img/x.jpg');
      expect(covers.saved['track:a']!.transform.scale, 2);
      expect(colors.saved['track:a'], 0xFF112233);
      expect(done.done, {'a'});
    });

    test('받은 곡 · 이미 한 곡은 읽지 않고, 앱 안의 커버 · 색은 덮지 않는다', () async {
      final library = FakeLibraryRepository([
        _track('a'),
        _track('b'),
        _track('d', source: TrackSource.download),
      ]);
      final covers = MemoryCoverRepository()
        ..saved['track:a'] = const CoverArt.web('https://mine');
      final colors = MemoryCoverColorRepository()..saved['track:a'] = 1;
      final reader = _Reader({
        'content://a': const FileTags(
          title: 'A',
          coverSource: 'https://img',
          coverColor: 2,
        ),
        'content://b': const FileTags(title: 'B'),
      });
      final done = _Done()..done.add('b');
      final useCase = RestoreFromFileTags(
        library,
        covers,
        colors,
        reader,
        done,
      );

      expect(await useCase(const NoParams()), 1);
      expect(reader.reads, ['a']);
      expect(covers.saved['track:a']!.url, 'https://mine');
      expect(colors.saved['track:a'], 1);
    });

    test('읽기에 실패한 곡은 기록하지 않아 다시 시도하고, 태그가 없으면 끝낸 것으로 본다', () async {
      final done = _Done();
      final reader = _Reader({
        'content://a': null,
        'content://b': FileTags.none,
      });
      final useCase = RestoreFromFileTags(
        FakeLibraryRepository([_track('a'), _track('b')]),
        MemoryCoverRepository(),
        MemoryCoverColorRepository(),
        reader,
        done,
      );
      expect(await useCase(const NoParams()), 0);
      expect(done.done, {'b'});
    });
  });

  group('태그 읽기', () {
    test('parseCoverExtra는 coverExtra가 쓴 값을 되읽는다', () {
      const art = CoverArt.web(
        'https://img/x.jpg',
        transform: CoverTransform(scale: 1.5, dx: .25, dy: -.5, rotation: 30),
      );
      final back = parseCoverExtra(coverExtra(art, null, 0xFF00AAFF));
      expect(back.source, 'https://img/x.jpg');
      expect(back.transform, art.transform);
      expect(back.color, 0xFF00AAFF);
    });

    test('parseCoverExtra: 없거나 깨진 칸은 기본값, 키는 대소문자 구분 없음', () {
      final empty = parseCoverExtra(const {});
      expect(empty.source, isNull);
      expect(empty.transform.isIdentity, isTrue);
      expect(empty.color, isNull);
      final bad = parseCoverExtra({
        'cover_transform': 'a,b',
        'cover_color': 'zz',
        'cover_source': ' https://x ',
      });
      expect(bad.transform.isIdentity, isTrue);
      expect(bad.color, isNull);
      expect(bad.source, 'https://x');
    });

    test('네이티브가 준 태그(소문자 키)를 앱 값으로 바꾼다', () {
      final a = FileTagSource.parse({
        'title': '제목',
        'artist': '가수',
        'album': '앨범',
        'genre': '록',
        'cover_source': 'https://img',
        'cover_color': 'ff112233',
      });
      expect([a.title, a.artist, a.album, a.genre], ['제목', '가수', '앨범', '록']);
      expect(a.coverSource, 'https://img');
      expect(a.coverColor, 0xFF112233);
      final b = FileTagSource.parse({'title': ' T '});
      expect([b.title, b.artist, b.album], ['T', '', '']);
      expect(FileTagSource.parse(const {}).isEmpty, isTrue);
    });
  });
}
