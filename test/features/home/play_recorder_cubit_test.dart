import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/database/app_database.dart';
import 'package:music_download_play_app/features/home/data/repositories/drift_play_history_repository.dart';
import 'package:music_download_play_app/features/home/domain/entities/home_summary.dart';
import 'package:music_download_play_app/features/home/domain/usecases/home_usecases.dart';
import 'package:music_download_play_app/features/home/presentation/bloc/play_recorder_cubit.dart';

import '../../helpers/fakes.dart';

Duration _s(int seconds) => Duration(seconds: seconds);

void main() {
  late MemoryPlayHistory history;
  late PlayRecorderCubit cubit;
  var clock = DateTime(2026, 10, 1, 12);

  /// [wall]만큼 시간이 흐른 뒤 재생 위치 [at]으로 상태가 바뀌었다고 알린다.
  void tick(String? track, int at, {int wall = 1, bool playing = true}) {
    clock = clock.add(_s(wall));
    cubit.playbackChanged(trackId: track, position: _s(at), isPlaying: playing);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    clock = DateTime(2026, 10, 1, 12);
    history = MemoryPlayHistory();
    cubit = PlayRecorderCubit(
      RecordPlay(history),
      UpdatePlayListened(history),
      now: () => clock,
    );
  });

  tearDown(() => cubit.close());

  test('재생이 시작되면 한 줄을 남기고, 흐른 만큼만 들은 시간으로 쌓는다', () async {
    tick('a', 0);
    tick('a', 1);
    tick('a', 2);
    tick('a', 3, playing: false); // 일시정지: 저장
    await settle();

    expect(history.plays, hasLength(1));
    expect(history.plays.single.trackId, 'a');
    expect(history.plays.single.listened, _s(2));
  });

  test('일시정지한 시간은 더하지 않고, 이어 재생해도 같은 기록에 쌓는다', () async {
    tick('a', 0);
    tick('a', 5, wall: 5);
    tick('a', 5, wall: 1, playing: false);
    tick('a', 5, wall: 600, playing: false); // 오래 멈춰 있음
    tick('a', 5, wall: 1); // 다시 재생: 이 순간부터 기준
    tick('a', 8, wall: 3);
    tick('a', 8, wall: 1, playing: false);
    await settle();

    expect(history.plays, hasLength(1));
    expect(history.plays.single.listened, _s(8));
  });

  test('시크로 위치가 뛴 구간은 실제 지난 시간만큼만 더한다', () async {
    tick('a', 0);
    tick('a', 100); // 앞으로 100초 건너뜀, 실제로는 1초
    tick('a', 20); // 뒤로 감기: 더하지 않음
    tick('a', 22, wall: 2);
    tick('a', 22, playing: false);
    await settle();

    expect(history.plays.single.listened, _s(1 + 0 + 2));
  });

  test('곡이 바뀌면 앞 곡을 저장하고 새 곡의 기록을 시작한다', () async {
    tick('a', 0);
    tick('a', 30, wall: 30);
    tick('b', 0); // 건너뛰기: 새 곡의 위치 0은 앞 곡 시간에 더하지 않는다
    tick('b', 4, wall: 4);
    tick('b', 4, playing: false);
    await settle();

    expect(history.plays.map((p) => (p.trackId, p.listened)), [
      ('a', _s(30)),
      ('b', _s(4)),
    ]);
  });

  test('멈춘 채 곡을 바꿨다가 재생하면 그때 새 곡의 기록이 생긴다', () async {
    tick('a', 0);
    tick('a', 10, wall: 10);
    tick('a', 10, playing: false);
    tick('b', 0, playing: false);
    await settle();
    expect(history.plays.map((p) => p.trackId), ['a']);

    tick('b', 0);
    tick('b', 7, wall: 7);
    tick('b', 7, playing: false);
    await settle();
    expect(history.plays.map((p) => (p.trackId, p.listened)), [
      ('a', _s(10)),
      ('b', _s(7)),
    ]);
  });

  test('재생하는 동안에도 일정 시간마다 저장한다', () async {
    final c = PlayRecorderCubit(
      RecordPlay(history),
      UpdatePlayListened(history),
      now: () => clock,
      flushEvery: _s(10),
    );
    addTearDown(c.close);
    for (var i = 0; i <= 12; i++) {
      clock = clock.add(_s(1));
      c.playbackChanged(trackId: 'a', position: _s(i), isPlaying: true);
    }
    await settle();

    expect(history.plays.single.listened, _s(10)); // 멈추지 않았어도 저장됨
  });

  test('곡이 없으면 아무것도 기록하지 않는다', () async {
    tick(null, 0);
    tick(null, 0, playing: false);
    await settle();
    expect(history.plays, isEmpty);
  });

  group('Drift', () {
    late AppDatabase db;
    late DriftPlayHistoryRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftPlayHistoryRepository(db);
    });

    tearDown(() => db.close());

    test('들은 시간을 기록하고 갱신한다', () async {
      final id = await repo.recordPlay(
        PlayRecord(trackId: 'a', playedAt: DateTime(2026, 10, 1)),
      );
      await repo.updateListened(id, _s(42));

      final plays = await repo.watchPlays().first;
      expect(plays.single.listened, _s(42));
    });

    test('옛 기록(들은 시간 0)은 곡 길이로 한 번 채운다 (v8 보정)', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              id: 'a',
              title: 'A',
              artist: '',
              album: '',
              durationMs: 180000,
              uri: 'u:a',
              source: 'device',
              addedAt: DateTime(2026, 9, 1),
            ),
          );
      await db
          .into(db.plays)
          .insert(
            PlaysCompanion.insert(
              trackId: 'a',
              playedAt: DateTime(2026, 10, 1),
            ),
          );
      await db
          .into(db.plays)
          .insert(
            PlaysCompanion.insert(
              trackId: 'a',
              playedAt: DateTime(2026, 10, 2),
              listenedMs: const Value(5000),
            ),
          );

      await db.customStatement(backfillListenedSql);

      final plays = await repo.watchPlays().first; // 최근 순
      expect(plays.map((p) => p.listened), [_s(5), _s(180)]);
    });
  });
}
