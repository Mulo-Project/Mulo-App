import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/covers/domain/usecases/cover_usecases.dart';
import 'package:music_download_play_app/features/covers/presentation/bloc/cover_cubit.dart';

import '../../helpers/fakes.dart';

CoverCubit _cubit(MemoryCoverRepository repo, FakeImageSource source) =>
    CoverCubit(
      load: LoadCovers(repo),
      pickFromDevice: PickCoverFromDevice(source, repo),
      clear: ClearCover(repo),
    );

void main() {
  test('pickFromDevice는 고른 사진을 저장하고 상태에 넣는다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource('/tmp/a.png'));
    addTearDown(c.close);
    expect(await c.pickFromDevice(CoverKey.track('t01')), isTrue);
    expect(c.state[CoverKey.track('t01')], '/tmp/a.png');
    expect(repo.saved.keys, [CoverKey.track('t01')]);
  });

  test('취소하면 바뀌지 않는다', () async {
    final c = _cubit(MemoryCoverRepository(), FakeImageSource());
    addTearDown(c.close);
    expect(await c.pickFromDevice(CoverKey.playlist('Focus')), isFalse);
    expect(c.state, isEmpty);
  });

  test('clear는 상태와 저장소에서 지운다', () async {
    final repo = MemoryCoverRepository();
    final c = _cubit(repo, FakeImageSource('/tmp/a.png'));
    addTearDown(c.close);
    await c.pickFromDevice(CoverKey.track('t01'));
    await c.pickFromDevice(CoverKey.track('t02'));
    await c.clear(CoverKey.track('t01'));
    expect(c.state.keys, [CoverKey.track('t02')]);
    expect(repo.saved.keys, [CoverKey.track('t02')]);
  });

  test('load는 저장된 커버를 불러온다', () async {
    final repo = MemoryCoverRepository()..saved['playlist:Focus'] = '/f.png';
    final c = _cubit(repo, FakeImageSource());
    addTearDown(c.close);
    await c.load();
    expect(c.state, {'playlist:Focus': '/f.png'});
  });
}
