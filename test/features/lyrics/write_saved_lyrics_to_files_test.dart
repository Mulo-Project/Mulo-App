import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/usecase/usecase.dart';
import 'package:music_download_play_app/features/library/domain/entities/track.dart';
import 'package:music_download_play_app/features/library/domain/repositories/track_tag_repository.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:music_download_play_app/features/lyrics/domain/usecases/lyrics_usecases.dart';

import '../../helpers/fakes.dart';

Track _t(String id) => Track(
  id: id,
  title: '곡 $id',
  artist: '가수',
  album: '앨범',
  duration: const Duration(minutes: 3),
  uri: 'content://$id',
  addedAt: DateTime(2026, 10, 26),
);

class _Embedded implements EmbeddedLyricsSource {
  _Embedded(this.inFile);

  final Map<String, String> inFile;

  @override
  Future<String?> read(String trackUri) async => inFile[trackUri];
}

/// 곡마다 정한 결과를 돌려주는 태그 가짜.
class _Tags extends FakeTrackTagRepository {
  _Tags(this.perTrack);

  final Map<String, TagWriteResult> perTrack;

  @override
  Future<TagWriteResult> writeLyrics(Track track, String lyrics) async {
    lyricsWritten[track.id] = lyrics;
    return perTrack[track.id] ?? TagWriteResult.written;
  }
}

void main() {
  late MemoryLyricsRepository lyrics;
  late FakeLibraryRepository library;

  setUp(() {
    lyrics = MemoryLyricsRepository()
      ..saved['a'] = '[00:01.00]하나'
      ..saved['b'] = '둘째 곡 가사'
      ..saved['c'] = '셋째 곡 가사'
      ..saved['gone'] = '보관함에 없는 곡'
      ..saved['f'] = '실패할 곡'
      ..saved['u'] = '못 쓰는 곡';
    library = FakeLibraryRepository([
      _t('a'),
      _t('b'),
      _t('c'),
      _t('f'),
      _t('u'),
      _t('none'),
    ]);
  });

  WriteSavedLyricsToFiles useCase(
    Map<String, String> inFile,
    Map<String, TagWriteResult> perTrack,
    FakeTrackTagRepository tags,
  ) => WriteSavedLyricsToFiles(lyrics, library, tags, _Embedded(inFile));

  test('대상 곡 수는 앱에 가사를 저장해 둔 보관함 곡만 센다', () async {
    expect(await CountSavedLyricsTracks(lyrics, library)(const NoParams()), 5);
  });

  test('곡마다 쓰고, 같은 가사는 건너뛰고, 실패 · 쓸 수 없음을 따로 센다', () async {
    final tags = _Tags({
      'f': TagWriteResult.failed,
      'u': TagWriteResult.unsupported,
    });
    final progress = <(int, int)>[];
    final result = await useCase({'content://b': '둘째 곡 가사\r\n'}, {}, tags)(
      WriteSavedLyricsToFilesParams(onProgress: (d, t) => progress.add((d, t))),
    );

    expect(result.written, 2); // a, c
    expect(result.alreadyThere, 1); // b: 파일에 같은 가사
    expect(result.failed, 1); // f
    expect(result.unsupported, 1); // u
    expect(tags.lyricsWritten.keys, containsAll(['a', 'c', 'f', 'u']));
    expect(tags.lyricsWritten.containsKey('b'), isFalse);
    expect(progress.first, (0, 5));
    expect(progress.last, (5, 5));
  });

  test('태그 쓰기에 실패해도 앱 안 가사는 그대로다', () async {
    final before = {...lyrics.saved};
    final result = await useCase(
      {},
      {},
      _Tags({for (final id in before.keys) id: TagWriteResult.failed}),
    )(const WriteSavedLyricsToFilesParams());
    expect(result.failed, 5);
    expect(result.written, 0);
    expect(lyrics.saved, before);
  });

  test('전부 쓸 수 없는 환경이면 지원하지 않는 것으로 본다', () async {
    final result = await useCase(
      {},
      {},
      FakeTrackTagRepository(), // 기본: unsupported
    )(const WriteSavedLyricsToFilesParams());
    expect(result.unsupported, 5);
    expect(result.nothingSupported, isTrue);
  });
}
