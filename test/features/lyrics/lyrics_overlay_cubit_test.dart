import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/lyrics/domain/entities/lyrics.dart';
import 'package:music_download_play_app/features/lyrics/domain/repositories/lyrics_overlay.dart';
import 'package:music_download_play_app/features/lyrics/domain/usecases/lyrics_overlay_usecases.dart';
import 'package:music_download_play_app/features/lyrics/presentation/bloc/lyrics_overlay_cubit.dart';

class _FakeOverlay implements LyricsOverlay {
  final shown = <({String id, int lines, String empty})>[];
  int hides = 0;

  @override
  Stream<void> watchClosed() => const Stream.empty();

  @override
  Future<bool> canDraw() async => true;

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<void> show(
    String trackId,
    List<LyricLine> lines, {
    required String hideLabel,
    required String offLabel,
    required int accent,
    String emptyLabel = '',
  }) async => shown.add((id: trackId, lines: lines.length, empty: emptyLabel));

  @override
  Future<void> setLyricsViewShown(bool shown) async {}

  @override
  Future<void> hide() async => hides++;
}

LyricsOverlayCubit _cubit(_FakeOverlay o) => LyricsOverlayCubit(
  canDraw: CanDrawLyricsOverlay(o),
  openPermission: OpenLyricsOverlayPermission(o),
  show: ShowLyricsOverlay(o),
  hide: HideLyricsOverlay(o),
  watchClosed: WatchLyricsOverlayClosed(o),
  setViewShown: SetLyricsViewShown(o),
);

void main() {
  test('싱크 가사가 없으면 창을 내리지 않고 이유 글만 올린다', () async {
    final o = _FakeOverlay();
    final cubit = _cubit(o);
    addTearDown(cubit.close);
    final synced = Lyrics.parse('[00:01.00]a\n[00:02.00]b');

    await cubit.sync(enabled: true, trackId: 't1', lyrics: synced);
    expect(o.shown.last, (id: 't1', lines: 2, empty: ''));

    // 다음 곡에 가사가 없다: 창을 내리지 않고 "가사가 없어요".
    await cubit.sync(
      enabled: true,
      trackId: 't2',
      lyrics: null,
      emptyLabel: '가사가 없어요',
    );
    expect(o.hides, 0);
    expect(o.shown.last, (id: 't2', lines: 0, empty: '가사가 없어요'));

    // 같은 내용은 다시 보내지 않는다.
    await cubit.sync(
      enabled: true,
      trackId: 't2',
      lyrics: null,
      emptyLabel: '가사가 없어요',
    );
    expect(o.shown.length, 2);

    // 싱크는 없고 글 가사만 있다: 줄을 시간 없이 올린다 (늘려서 볼 수 있게).
    await cubit.sync(
      enabled: true,
      trackId: 't3',
      lyrics: Lyrics.parse('첫 줄\n둘째 줄'),
      emptyLabel: '싱크된 가사가 없어요',
    );
    expect(o.shown.last, (id: 't3', lines: 2, empty: '싱크된 가사가 없어요'));

    // 꺼지면 내린다.
    await cubit.sync(enabled: false, trackId: null, lyrics: null);
    expect(o.hides, 1);
  });
}
