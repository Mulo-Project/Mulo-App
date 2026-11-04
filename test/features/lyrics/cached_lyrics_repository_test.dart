import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/lyrics/data/repositories/cached_lyrics_repository.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_repository.dart';

class _CountingRepo implements LyricsRepository {
  final texts = <String, String>{};
  int loads = 0;
  Completer<void>? gate;

  @override
  Future<Lyrics?> load(String trackId, String trackUri) async {
    loads++;
    final text = texts[trackId];
    await gate?.future;
    return text == null ? null : Lyrics.parse(text);
  }

  @override
  Future<Lyrics?> save(String trackId, String text) async {
    final lyrics = Lyrics.parse(text);
    if (lyrics == null) {
      texts.remove(trackId);
    } else {
      texts[trackId] = text;
    }
    return lyrics;
  }

  @override
  Future<void> remove(String trackId) async => texts.remove(trackId);
}

void main() {
  late _CountingRepo inner;

  setUp(() => inner = _CountingRepo()..texts['a'] = 'hello');

  test('두 번째 load는 안쪽 저장소를 거치지 않는다', () async {
    final repo = CachedLyricsRepository(inner);
    final first = await repo.load('a', 'u');
    final second = await repo.load('a', 'u');
    expect(first?.raw, 'hello');
    expect(second, same(first));
    expect(inner.loads, 1);
  });

  test('가사 없음도 캐시한다', () async {
    final repo = CachedLyricsRepository(inner);
    expect(await repo.load('none', 'u'), isNull);
    expect(await repo.load('none', 'u'), isNull);
    expect(inner.loads, 1);
  });

  test('동시에 부르면 한 번만 읽는다', () async {
    inner.gate = Completer<void>();
    final repo = CachedLyricsRepository(inner);
    final f1 = repo.load('a', 'u');
    final f2 = repo.load('a', 'u');
    inner.gate!.complete();
    await Future.wait([f1, f2]);
    expect(inner.loads, 1);
  });

  test('save · remove 하면 캐시가 바로 바뀐다', () async {
    final repo = CachedLyricsRepository(inner);
    await repo.load('a', 'u');
    await repo.save('a', 'new');
    expect((await repo.load('a', 'u'))?.raw, 'new');
    await repo.remove('a');
    expect(await repo.load('a', 'u'), isNull);
  });

  test('불러오는 도중 save 하면 옛 결과를 캐시하지 않는다', () async {
    inner.gate = Completer<void>();
    final repo = CachedLyricsRepository(inner);
    final pending = repo.load('a', 'u');
    await repo.save('a', 'new');
    inner.gate!.complete();
    await pending;
    inner.gate = null;
    expect((await repo.load('a', 'u'))?.raw, 'new');
  });

  test('재생 주소가 바뀌면 다시 읽는다', () async {
    final repo = CachedLyricsRepository(inner);
    await repo.load('a', 'u1');
    await repo.load('a', 'u2');
    expect(inner.loads, 2);
  });

  test('곡 수가 넘으면 가장 오래 안 쓴 곡부터 뺀다', () async {
    for (final id in ['a', 'b', 'c']) {
      inner.texts[id] = id;
    }
    final repo = CachedLyricsRepository(inner, maxEntries: 2);
    await repo.load('a', 'u');
    await repo.load('b', 'u');
    await repo.load('a', 'u'); // a를 최근으로
    await repo.load('c', 'u'); // b가 빠진다
    expect(inner.loads, 3);
    await repo.load('a', 'u');
    await repo.load('c', 'u');
    expect(inner.loads, 3);
    await repo.load('b', 'u');
    expect(inner.loads, 4);
  });

  test('글자 수 상한을 넘어도 뺀다', () async {
    inner.texts['a'] = 'x' * 60;
    inner.texts['b'] = 'y' * 60;
    final repo = CachedLyricsRepository(inner, maxChars: 100);
    await repo.load('a', 'u');
    await repo.load('b', 'u');
    await repo.load('a', 'u');
    expect(inner.loads, 3);
  });

  test('clear 하면 전부 다시 읽는다', () async {
    final repo = CachedLyricsRepository(inner);
    await repo.load('a', 'u');
    repo.clear();
    await repo.load('a', 'u');
    expect(inner.loads, 2);
  });
}
